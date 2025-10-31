------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    esp.vhd
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
--
-- This file was originally part of the ESP project source code, available at:
-- https://github.com/sld-columbia/esp
------------------------------------------------------------------------------

-- Copyright (c) 2011-2023 Columbia University, System Level Design Group
-- SPDX-License-Identifier: Apache-2.0

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;  --GM change
use work.esp_global.all;
use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;
use work.gencomp.all;
use work.leon3.all;
use work.net.all;
-- pragma translate_off
use work.sim.all;
library unisim;
use unisim.all;
-- pragma translate_on
use work.monitor_pkg.all;
use work.sldacc.all;
use work.tile.all;
use work.nocpackage.all;
use work.cachepackage.all;
use work.coretypes.all;
use work.grlib_config.all;
use work.socmap.all;
use work.tiles_pkg.all;
use work.tiles_fpga_pkg.all;

use work.misc.all; --GM change: I need this library for the rstgen
use work.esp_csr_pkg.all; --GM change: I need this library for freq data info
entity esp is
  generic (
    SIMULATION : boolean := false);
  port (
    rstn_sys          : in    std_logic;
    rstn_init         : in    std_logic;  --GM change: a reset for clocking resources
    clk_sys           : in    std_logic;
    clk_noc           : in    std_logic; --GM change: a variable clock for the interconnect resources
    rstn_noc          : in    std_logic; --GM change: reset synchronized with the icclk
    pllbypass         : in    std_logic_vector(CFG_TILES_NUM - 1 downto 0);
    lock_tiles        : out   std_logic;  --GM change: bringing internal lock to the top module
    uart_rxd          : in    std_logic;  -- UART1_RX (u1i.rxd)
    uart_txd          : out   std_logic;  -- UART1_TX (u1o.txd)
    uart_ctsn         : in    std_logic;  -- UART1_RTSN (u1i.ctsn)
    uart_rtsn         : out   std_logic;  -- UART1_RTSN (u1o.rtsn)
    cpuerr            : out   std_logic;
    ddr_ahbsi         : out ahb_slv_in_vector_type(0 to MEM_ID_RANGE_MSB);
    ddr_ahbso         : in  ahb_slv_out_vector_type(0 to MEM_ID_RANGE_MSB);
    mon_noc           : out monitor_noc_matrix(1 to 6, 0 to CFG_TILES_NUM-1);
    mon_mem           : out monitor_mem_vector(0 to CFG_NMEM_TILE + CFG_NSLM_TILE + CFG_NSLMDDR_TILE - 1);
    --External reset
    rst_ext_out       : out std_ulogic;
    --DFS frequency info
    freq_data_out     : out std_logic_vector(GM_FREQ_DW-1 downto 0);  --GM change: input freq data
    freq_valid_out    : out std_logic --GM change: freq data valid
    );
end;


architecture rtl of esp is

-------------------------------------------------------------------------------
-- Signals --------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Each tile may (potentially) outputs as many clocks as the number of tiles.
-- This array is pretty big: I expect that Vivado is able to reduce its size by
-- removing the unused arrays, but I may decide to make it smaller anyway.
--type clock_tiles_out_t is array (0 to CFG_TILES_NUM-1) of std_ulogic_vector(CFG_TILES_NUM-1 downto 0);

-- Clocks and resets
signal clk_tiles_out     : std_ulogic_vector(CFG_TILES_NUM-1 downto 0);     --Output clock of all the tiles
signal clk_domains       : std_logic_vector(CLOCK_DOMAINS_NUM-1 downto 0);  --Input clock of all the tiles
signal lock_dfs          : std_logic_vector(CFG_TILES_NUM-1 downto 0);      --List of clock locks for all the DFS
signal lock_tiles_int    : std_logic;                                       --Global lock af all the clocks in all the tiles


-- DFS frequency info
signal freq_data  : freq_reg_t;
signal freq_valid : std_logic_vector(domains_num-1 downto 0);


-- Monitor
type monitor_noc_cast_vector is array (0 to CFG_TILES_NUM-1) of monitor_noc_vector(1 to num_noc_planes);
signal mon_noc_vec : monitor_noc_cast_vector;


-- NOC
signal noc_data_n_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_s_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_w_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_e_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_void_in    : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_stop_in         : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_n_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_s_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_w_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_e_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_void_out   : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_stop_out        : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);


-- Misc
signal cpuerr_vec    : std_logic_vector(0 to CFG_NCPU_TILE-1);


--attribute keep                          : string;

--attribute keep of clk_domains       : signal is "true";

--GM change: need the synchronizer to connect nocs with different freqs
component synchronizer is
  generic (
    DATA_WIDTH : integer
    );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0));
end component;

--GM change: a stupid function 'cause VHDL doesn't accept conditional constant declaration...
function check_resync(tile_domain:integer; noc_domain:integer)
return integer is
begin
  if tile_domain = noc_domain then
      return 0;
  else
      return 1;
  end if;
end function;


begin

  -------------------------------------------------------------------------------
  -- CLOCK MANAGEMENT
  -------------------------------------------------------------------------------

  --Clock domains generation
  clk_domains(0) <= clk_noc; -- Clock domain 0 is reserved for the NoC clock
  clock_domains: for i in 1 to CLOCK_DOMAINS_NUM-1 generate
    clk_domains(i) <= clk_tiles_out(domain_master_tile(i));  -- Clock domain i is taken from the master tile of the domain
  end generate clock_domains;

  --GM change: process to "and" all the singular lock_dfs signals and generate a general lock
  process(lock_dfs)
  variable lock_temp : std_logic;
  begin
  lock_temp := '1';
    for i in 0 to CFG_TILES_NUM-1 loop
      lock_temp := lock_temp and lock_dfs(i);
    end loop;
    lock_tiles_int <= lock_temp;
  end process;
  lock_tiles <= lock_tiles_int;

  cpuerr <= cpuerr_vec(0);

  --GM change: bring domain 0 freq info to the top
  freq_data_out     <= freq_data(0);  --GM change: input freq data
  freq_valid_out    <= freq_valid(0); --GM change: freq data empty

  -----------------------------------------------------------------------------
  -- NOC CONNECTIONS
  -----------------------------------------------------------------------------

  -- WARNING: the functionality that allowed to change the frequency of the NoC in a tile is now discontinued.
  -- I leave here all the necessary code (specifically, the resynchronizers between the routers), but since some
  -- signals are changed I need to comment out some parts.
  meshgen_y: for y in 0 to CFG_YLEN-1 generate
    meshgen_x: for x in 0 to CFG_XLEN-1 generate
      meshgen_noc: for plane in 0 to num_noc_planes-1 generate
        y_0: if (y=0) generate
          -- North port is unconnected
          noc_data_n_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(0) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(0) <= '0';
        end generate y_0;

        y_non_0: if (y /= 0) generate
          -- North port is connected

          --Same clock domain: no need for a resync
          no_resync_y_non_0: if (noc_domain(y*CFG_XLEN + x) = noc_domain((y-1)*CFG_XLEN + x)) generate
            noc_data_n_in(y*CFG_XLEN + x)(plane)       <= noc_data_s_out((y-1)*CFG_XLEN + x)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(0) <= noc_data_void_out((y-1)*CFG_XLEN + x)(plane)(1);
            noc_stop_in(y*CFG_XLEN + x)(plane)(0)      <= noc_stop_out((y-1)*CFG_XLEN + x)(plane)(1);
          end generate no_resync_y_non_0;

          --Different clock domains: need a resync
          resync_y_non_0: if (noc_domain(y*CFG_XLEN + x) /= noc_domain((y-1)*CFG_XLEN + x)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> south output port of tile (x, y-1)
            clk_wr <= '0'; --clk_tile(noc_domain_master((y-1)*CFG_XLEN + x));
            rst_wr <= '0'; --rst_local(noc_domain_master((y-1)*CFG_XLEN + x));
            flit_wr <= noc_data_s_out((y-1)*CFG_XLEN + x)(plane);
            wren <= not noc_data_void_out((y-1)*CFG_XLEN + x)(plane)(1);
            noc_stop_in((y-1)*CFG_XLEN + x)(plane)(1) <= full;
            --Read port -> north input port of tile (x, y)
            clk_rd <= '0'; --clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= '0'; --rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_n_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(0);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(0) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_y_non_0;
        end generate y_non_0;

        y_YLEN: if (y=CFG_YLEN-1) generate
          -- South port is unconnected
          noc_data_s_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(1) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(1) <= '0';
        end generate y_YLEN;

        y_non_YLEN: if (y /= CFG_YLEN-1) generate
          -- south port is connected

          --Same clock domain: no need for a resync
          no_resync_y_non_YLEN: if (noc_domain(y*CFG_XLEN + x) = noc_domain((y+1)*CFG_XLEN + x)) generate
            noc_data_s_in(y*CFG_XLEN + x)(plane)       <= noc_data_n_out((y+1)*CFG_XLEN + x)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(1) <= noc_data_void_out((y+1)*CFG_XLEN + x)(plane)(0);
            noc_stop_in(y*CFG_XLEN + x)(plane)(1)      <= noc_stop_out((y+1)*CFG_XLEN + x)(plane)(0);
          end generate no_resync_y_non_YLEN;

          --Different clock domains: need a resync
          resync_y_non_YLEN: if (noc_domain(y*CFG_XLEN + x) /= noc_domain((y+1)*CFG_XLEN + x)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> north output port of tile (x, y+1)
            clk_wr <= '0'; --clk_tile(noc_domain_master((y+1)*CFG_XLEN + x));
            rst_wr <= '0'; --rst_local(noc_domain_master((y+1)*CFG_XLEN + x));
            flit_wr <= noc_data_n_out((y+1)*CFG_XLEN + x)(plane);
            wren <= not noc_data_void_out((y+1)*CFG_XLEN + x)(plane)(0);
            noc_stop_in((y+1)*CFG_XLEN + x)(plane)(0) <= full;
            --Read port -> south input port of tile (x, y)
            clk_rd <= '0'; --clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= '0'; --rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_s_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(1);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(1) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_y_non_YLEN;
        end generate y_non_YLEN;

        x_0: if (x=0) generate
          -- West port is unconnected
          noc_data_w_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(2) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(2) <= '0';
        end generate x_0;

        x_non_0: if (x /= 0) generate
          -- West port is connected

          --Same clock domain: no need for a resync
          no_resync_x_non_0: if (noc_domain(y*CFG_XLEN + x) = noc_domain(y*CFG_XLEN + x - 1)) generate
            noc_data_w_in(y*CFG_XLEN + x)(plane)      <= noc_data_e_out(y*CFG_XLEN + x - 1)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(2) <= noc_data_void_out(y*CFG_XLEN + x - 1)(plane)(3);
            noc_stop_in(y*CFG_XLEN + x)(plane)(2)      <= noc_stop_out(y*CFG_XLEN + x - 1)(plane)(3);
          end generate no_resync_x_non_0;

          --Different clock domains: need a resync
          resync_x_non_0: if (noc_domain(y*CFG_XLEN + x) /= noc_domain(y*CFG_XLEN + x - 1)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> east output port of tile (x-1, y)
            clk_wr <= '0'; --clk_tile(noc_domain_master(y*CFG_XLEN + x - 1));
            rst_wr <= '0'; --rst_local(noc_domain_master(y*CFG_XLEN + x - 1));
            flit_wr <= noc_data_e_out(y*CFG_XLEN + x - 1)(plane);
            wren <= not noc_data_void_out(y*CFG_XLEN + x - 1)(plane)(3);
            noc_stop_in(y*CFG_XLEN + x - 1)(plane)(3) <= full;
            --Read port -> west input port of tile (x, y)
            clk_rd <= '0'; --clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= '0'; --rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_w_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(2);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(2) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_x_non_0;

        end generate x_non_0;

        x_XLEN: if (x=CFG_XLEN-1) generate
          -- East port is unconnected
          noc_data_e_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(3) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(3) <= '0';
        end generate x_XLEN;

        x_non_XLEN: if (x /= CFG_XLEN-1) generate
          -- East port is connected

          --Same clock domain: no need for a resync
          no_resync_x_non_XLEN: if (noc_domain(y*CFG_XLEN + x) = noc_domain(y*CFG_XLEN + x + 1)) generate
            noc_data_e_in(y*CFG_XLEN + x)(plane)         <= noc_data_w_out(y*CFG_XLEN + x + 1)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(3)   <= noc_data_void_out(y*CFG_XLEN + x + 1)(plane)(2);
            noc_stop_in(y*CFG_XLEN + x)(plane)(3)        <= noc_stop_out(y*CFG_XLEN + x + 1)(plane)(2);
          end generate no_resync_x_non_XLEN;

          --Different clock domains: need a resync
          resync_x_non_XLEN: if (noc_domain(y*CFG_XLEN + x) /= noc_domain(y*CFG_XLEN + x + 1)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> west output port of tile (x+1, y)
            clk_wr <= '0'; --clk_tile(noc_domain_master(y*CFG_XLEN + x + 1));
            rst_wr <= '0'; --rst_local(noc_domain_master(y*CFG_XLEN + x + 1));
            flit_wr <= noc_data_w_out(y*CFG_XLEN + x + 1)(plane);
            wren <= not noc_data_void_out(y*CFG_XLEN + x + 1)(plane)(2);
            noc_stop_in(y*CFG_XLEN + x + 1)(plane)(2) <= full;
            --Read port -> east input port of tile (x, y)
            clk_rd <= '0'; --clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= '0'; --rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_e_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(3);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(3) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_x_non_XLEN;
        end generate x_non_XLEN;
      end generate meshgen_noc;
    end generate meshgen_x;
  end generate meshgen_y;


  -----------------------------------------------------------------------------
  -- TILES
  -----------------------------------------------------------------------------
  tiles_gen: for i in 0 to CFG_TILES_NUM - 1  generate

  -----------------------------------------------------------------------------
  -- EMPTY TILE
  -----------------------------------------------------------------------------

    empty_tile: if tile_type(i) = 0 generate
    tile_empty_i: fpga_tile_empty
      generic map (
        SIMULATION   => SIMULATION,
        ROUTER_PORTS => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC     => CFG_HAS_SYNC) --GM change: empty tile works at 50MHz reference, thus it must always be synchronized
      port map (
        rstn_sys           => rstn_sys,
        clk_sys            => clk_sys,
        rstn_noc           => rstn_noc,
        clk_noc            => clk_noc,
        lock_rstn_tile     => lock_tiles_int,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i));
      lock_dfs(i) <= '1';   -- No DFS implemented in this kind of tile
      clk_tiles_out(i) <= '0'; --(others => '0');
    end generate empty_tile;

  -----------------------------------------------------------------------------
  -- CPU TILE
  -----------------------------------------------------------------------------

    cpu_tile: if tile_type(i) = 1 generate
-- pragma translate_off
      assert tile_cpu_id(i) /= -1 report "Undefined CPU ID for CPU tile" severity error;
-- pragma translate_on
      tile_cpu_i: fpga_tile_cpu

      generic map (
        SIMULATION         => SIMULATION,
        this_has_dvfs      => tile_has_dvfs(i),
        this_has_pll       => tile_has_pll(i),
        this_extra_clk_buf => extra_clk_buf(i),
        ROUTER_PORTS       => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC           => check_resync(tile_domain(i), noc_domain(i)),--CFG_HAS_SYNC) --GM change: has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
        this_clock_domain  => tile_domain(i), --GM change: clock domain of this tile
        pll_clk_freq       => domain_freq(tile_domain(i)), --GM change: clock frequency that must be returned from the pll (1=max, 10=min)
        this_tile_id       => i
    )
      port map (
        rstn_init          => rstn_init,
        rstn_sys           => rstn_sys,
        clk_sys            => clk_sys,
        rstn_noc           => rstn_noc,
        clk_noc            => clk_noc,
        clk_tile_in        => clk_domains(tile_domain(i)),--clk_tiles_out(tile_domain_master(i))(get_tile_input_clock(i)),--clk_domains(tile_domain(i)),
        clk_dfs_out        => clk_tiles_out(i),
        lock_dfs_out       => lock_dfs(i),
        lock_rstn_tile     => lock_tiles_int,
        cpuerr             => cpuerr_vec(tile_cpu_id(i)),
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        freq_data_in   => freq_data(tile_domain(i)),  --GM change: input freq data
        freq_valid_in  => freq_valid(tile_domain(i))  --GM change: freq data empty
        );
    end generate cpu_tile;

  -----------------------------------------------------------------------------
  -- ACC TILE
  -----------------------------------------------------------------------------

    accelerator_tile: if tile_type(i) = 2 generate
-- pragma translate_off
      assert tile_device(i) /= 0 report "Undefined device ID for accelerator tile" severity error;
-- pragma translate_on
      tile_acc_i: fpga_tile_acc
      generic map (
        SIMULATION  => SIMULATION,  --GM change: need this bool for pll library mismatch
        this_hls_conf      => tile_design_point(i),
        this_device        => tile_device(i),
        this_irq_type      => tile_irq_type(i),
        this_has_l2        => tile_has_l2(i),
        this_has_dvfs      => tile_has_dvfs(i),
        this_has_pll       => tile_has_pll(i),
        ROUTER_PORTS       => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC           => check_resync(tile_domain(i), noc_domain(i)),--CFG_HAS_SYNC --GM change: has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
        pll_clk_freq       => domain_freq(tile_domain(i)), --GM change: clock frequency that must be returned from the pll (1=max, 10=min)
        this_tile_id       => i --GM change: why this info is not already passed as parameter???
    )
      port map (
        rstn_init          => rstn_init,
        rstn_sys           => rstn_sys,
        clk_sys            => clk_sys,
        rstn_noc           => rstn_noc,
        clk_noc            => clk_noc,
        clk_tile_in        => clk_domains(tile_domain(i)),--clk_tiles_out(tile_domain_master(i))(get_tile_input_clock(i)),--clk_domains(tile_domain(i)),
        clk_dfs_out        => clk_tiles_out(i),
        lock_dfs_out       => lock_dfs(i),
        lock_rstn_tile     => lock_tiles_int,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        freq_data_in   => freq_data(tile_domain(i)),  --GM change: input freq data
        freq_valid_in  => freq_valid(tile_domain(i))  --GM change: freq data empty
        );
    end generate accelerator_tile;

  -----------------------------------------------------------------------------
  -- IO TILE
  -----------------------------------------------------------------------------

    io_tile: if tile_type(i) = 3 generate
      tile_io_i : fpga_tile_io
      generic map (
        SIMULATION   => SIMULATION,
        ROUTER_PORTS => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC     => CFG_HAS_SYNC --GM change: IO tile has its own frequency, thus it must always be synchronized
        )
      port map (
        rstn_sys           => rstn_sys,
        clk_sys            => clk_sys,
        rstn_noc           => rstn_noc,
        clk_noc            => clk_noc,
        lock_rstn_tile     => lock_tiles_int,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- Ethernet MDC Scaler configuration
        mdcscaler          => open,
        -- I/O bus interfaces
        uart_rxd           => uart_rxd,
        uart_txd           => uart_txd,
        uart_ctsn          => uart_ctsn,
        uart_rtsn          => uart_rtsn,
        -- NOC
        noc_data_n_in      => noc_data_n_in(i),
        noc_data_s_in      => noc_data_s_in(i),
        noc_data_w_in      => noc_data_w_in(i),
        noc_data_e_in      => noc_data_e_in(i),
        noc_data_void_in   => noc_data_void_in(i),
        noc_stop_in        => noc_stop_in(i),
        noc_data_n_out     => noc_data_n_out(i),
        noc_data_s_out     => noc_data_s_out(i),
        noc_data_w_out     => noc_data_w_out(i),
        noc_data_e_out     => noc_data_e_out(i),
        noc_data_void_out  => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec    => mon_noc_vec(i),
        rst_ext_out        => rst_ext_out,
        freq_data_out      => freq_data,    --GM change: number describing freq
        freq_valid_out     => freq_valid  --GM change: validity signal for freqs
      );
      lock_dfs(i) <= '1';   -- No DFS implemented in this kind of tile
      clk_tiles_out(i) <= '0'; --(others => '0');
    end generate io_tile;

  -----------------------------------------------------------------------------
  -- MEM TILE
  -----------------------------------------------------------------------------

    mem_tile: if tile_type(i) = 4 generate
      tile_mem_i: fpga_tile_mem
      generic map (
        ROUTER_PORTS => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC     => check_resync(tile_domain(i), noc_domain(i)))--CFG_HAS_SYNC) --GM change: has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
      port map (
        rstn_sys           => rstn_sys,
        clk_tile_in        => clk_noc,
        rstn_noc           => rstn_noc,
        clk_noc            => clk_noc,
        lock_rstn_tile     => lock_tiles_int,
        -- DDR controller ports (this_has_ddr -> 1)
        dco_clk_div2       => open,
        dco_clk_div2_90    => open,
        ddr_ahbsi          => ddr_ahbsi(tile_mem_id(i)),
        ddr_ahbso          => ddr_ahbso(tile_mem_id(i)),
        ddr_cfg0           => open,
        ddr_cfg1           => open,
        ddr_cfg2           => open,
        mem_id             => open,
        -- FPGA proxy memory link (this_has_ddr -> 0)
        fpga_data_in       => (others => '0'),
        fpga_data_out      => open,
        fpga_oen           => open,
        fpga_valid_in      => '0',
        fpga_valid_out     => open,
        fpga_clk_in        => '0',
        fpga_clk_out       => open,
        fpga_credit_in     => '0',
        fpga_credit_out    => open,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        mon_mem            => mon_mem(tile_mem_id(i)));
        lock_dfs(i) <= '1';   -- No DFS implemented in this kind of tile
        clk_tiles_out(i) <= '0'; --(others => '0');
    end generate mem_tile;

    dpr_tile: if tile_type(i) = 5 generate
      tile_dpr_i: fpga_tile_dpr
      generic map (
        this_hls_conf      => tile_design_point(i),
        this_device        => tile_device(i),
        this_irq_type      => tile_irq_type(i),
        this_has_l2        => tile_has_l2(i),
        this_has_dvfs      => tile_has_dvfs(i),
        this_has_pll       => tile_has_pll(i),
        ROUTER_PORTS       => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC           => check_resync(tile_domain(i), noc_domain(i)),--CFG_HAS_SYNC --GM change: has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
        pll_clk_freq       => domain_freq(tile_domain(i)), --GM change: clock frequency that must be returned from the pll (1=max, 10=min)
        this_tile_id       => i
      )
      port map (
        rstn_init          => rstn_init,
        rstn_sys           => rstn_sys,
        clk_sys            => clk_sys,
        rstn_noc           => rstn_noc,
        clk_noc            => clk_noc,
        clk_tile_in        => clk_domains(tile_domain(i)),--clk_tiles_out(tile_domain_master(i))(get_tile_input_clock(i)),
        clk_dfs_out        => clk_tiles_out(i),
        lock_dfs_out       => lock_dfs(i),
        lock_rstn_tile     => lock_tiles_int,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        freq_data_in   => freq_data(tile_domain(i)),  --GM change: input freq data
        freq_valid_in  => freq_valid(tile_domain(i))  --GM change: freq data empty
        );
    end generate dpr_tile;

  end generate tiles_gen;


  no_mem_tile_gen: if CFG_NMEM_TILE = 0 generate
    ddr_ahbsi(0) <= ahbs_in_none;
  end generate no_mem_tile_gen;

  -----------------------------------------------------------------------------
  -- MONITOR
  -----------------------------------------------------------------------------

  monitor_noc_gen: for i in 1 to num_noc_planes generate
    monitor_noc_tiles_gen: for j in 0 to CFG_TILES_NUM-1 generate
      mon_noc(i,j) <= mon_noc_vec(j)(i);
    end generate monitor_noc_tiles_gen;
  end generate monitor_noc_gen;

end;
