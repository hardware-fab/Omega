------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    fpga_tile_acc.vhd
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

-----------------------------------------------------------------------------
--  Accelerator Tile
------------------------------------------------------------------------------

library ieee;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.esp_global.all;
use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;
use work.gencomp.all;
use work.monitor_pkg.all;
use work.esp_csr_pkg.all;
use work.jtag_pkg.all;
use work.sldacc.all;
use work.nocpackage.all;
use work.cachepackage.all;
use work.tile.all;
use work.misc.all;
use work.coretypes.all;
use work.esp_acc_regmap.all;
use work.socmap.all;
use work.grlib_config.all;
use work.tiles_pkg.all;

entity fpga_tile_acc is
  generic (
    SIMULATION  :  boolean := false;  --GM change: need this bool for pll library mismatch
    this_hls_conf      : hlscfg_t             := 0;
    this_device        : devid_t              := 0;
    this_irq_type      : integer              := 0;
    this_has_l2        : integer range 0 to 1 := 0;
    this_has_dvfs      : integer range 0 to 1 := 0;
    this_has_pll       : integer range 0 to 1 := 0;
    ROUTER_PORTS       : ports_vec            := "11111";
    HAS_SYNC           : integer range 0 to 1 := 1;
    pll_clk_freq       : integer range 0 to 10 := 0; --GM change: clock frequency that must be returned from the pll (1=max, 10=min)
    this_tile_id       : integer range 0 to CFG_TILES_NUM := 0 --GM change
    );
  port (
    rstn_init          : in  std_ulogic;
    rstn_sys           : in  std_ulogic;
    clk_sys            : in  std_ulogic;
    rstn_noc           : in  std_ulogic;
    clk_noc            : in  std_ulogic;
    clk_tile_in        : in  std_ulogic;
    clk_dfs_out        : out std_ulogic;--_vector(CFG_TILES_NUM-1 downto 0);
    lock_dfs_out       : out std_ulogic;
    lock_rstn_tile     : in  std_ulogic;
    -- Test interface
    tdi                : in  std_logic;
    tdo                : out std_logic;
    tms                : in  std_logic;
    tclk               : in  std_logic;
    -- NOC
    noc_data_n_in     : in  noc_flit_vector;
    noc_data_s_in     : in  noc_flit_vector;
    noc_data_w_in     : in  noc_flit_vector;
    noc_data_e_in     : in  noc_flit_vector;
    noc_data_void_in  : in  partial_handshake_vector;
    noc_stop_in       : in  partial_handshake_vector;
    noc_data_n_out    : out noc_flit_vector;
    noc_data_s_out    : out noc_flit_vector;
    noc_data_w_out    : out noc_flit_vector;
    noc_data_e_out    : out noc_flit_vector;
    noc_data_void_out : out partial_handshake_vector;
    noc_stop_out      : out partial_handshake_vector;
    noc_mon_noc_vec   : out monitor_noc_vector(num_noc_planes-1 downto 0);
    freq_data_in       : in std_logic_vector(GM_FREQ_DW-1 downto 0);  --GM change: input freq data
    freq_valid_in      : in std_logic --GM change: freq data valid
    );

end;

architecture rtl of fpga_tile_acc is

  --GM change: I add the declaration of the DFS module
  component clockManager
    generic(
      PLL_FREQ                                 :    integer := 1;
      RANDOM_FREQ                              :    integer := 0
      --N_CLOCK_OUT                              :    integer := 1
    );
    port (
      rst_in                                   :     in std_logic;
      clk_in                                   :     in std_logic;
      mmcm_clk_o                               :     out std_ulogic;--_vector(N_CLOCK_OUT-1 downto 0);
      mmcm_locked_o                            :     out std_logic;
      freq_data_in                             :     in std_logic_vector(8-1 downto 0);
      freq_valid_in                            :     in std_logic
      );
  end component;

  -- Number of clocks to be generated
  --constant N_CLOCKS   : integer := get_tiles_number_in_clock_domain(tile_domain(this_tile_id));

  -- Tile parameters
  signal this_local_y : local_yx;
  signal this_local_x : local_yx;

  -- DCO reset -> keeping the logic compliant with the asic flow
  signal dco_rstn : std_ulogic;

  -- Tile interface signals
  signal test_output_port_s   : noc_flit_vector;
  signal test_data_void_out_s : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal test_stop_in_s       : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal test_input_port_s    : noc_flit_vector;
  signal test_data_void_in_s  : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal test_stop_out_s      : std_ulogic_vector(num_noc_planes-1 downto 0);

  signal noc_mon_noc_vec_int  : monitor_noc_vector(num_noc_planes-1 downto 0);

  -- Noc signals
  signal noc_stop_in_s         : handshake_vector;
  signal noc_stop_out_s        : handshake_vector;
  signal noc_acc_stop_in       : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_acc_stop_out      : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_data_void_in_s    : handshake_vector;
  signal noc_data_void_out_s   : handshake_vector;
  signal noc_acc_data_void_in  : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_acc_data_void_out : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_input_port        : noc_flit_vector;
  signal noc_output_port       : noc_flit_vector;

  attribute keep              : string;
  attribute keep of noc_acc_stop_in       : signal is "true";
  attribute keep of noc_acc_stop_out      : signal is "true";
  attribute keep of noc_acc_data_void_in  : signal is "true";
  attribute keep of noc_acc_data_void_out : signal is "true";
  attribute keep of noc_input_port        : signal is "true";
  attribute keep of noc_output_port       : signal is "true";
  attribute keep of noc_data_n_in     : signal is "true";
  attribute keep of noc_data_s_in     : signal is "true";
  attribute keep of noc_data_w_in     : signal is "true";
  attribute keep of noc_data_e_in     : signal is "true";
  attribute keep of noc_data_void_in  : signal is "true";
  attribute keep of noc_stop_in       : signal is "true";
  attribute keep of noc_data_n_out    : signal is "true";
  attribute keep of noc_data_s_out    : signal is "true";
  attribute keep of noc_data_w_out    : signal is "true";
  attribute keep of noc_data_e_out    : signal is "true";
  attribute keep of noc_data_void_out : signal is "true";
  attribute keep of noc_stop_out      : signal is "true";

  --GM change: my signals
  signal clk_tile    : std_ulogic;
  signal rstn_tile   : std_ulogic;

begin

  -- Tile with DFS
  clock_with_dfs: if this_has_pll /= 0 generate
    dfs_manager_1 : clockManager
    generic map(
      PLL_FREQ => pll_clk_freq,
      RANDOM_FREQ => 0
      --N_CLOCK_OUT => N_CLOCKS
    )
    port map(
      rst_in => rstn_init,
      clk_in => clk_sys,
      mmcm_clk_o => clk_tile, --clk_dfs_out(N_CLOCKS-1 downto 0),
      mmcm_locked_o => lock_dfs_out,
      freq_data_in => freq_data_in,
      freq_valid_in => freq_valid_in
    );
    --clk_dfs_out(clk_dfs_out'HIGH downto N_CLOCKS) <= (others => '0');
    clk_dfs_out <= clk_tile;
  end generate clock_with_dfs;


  --clk_tile <= clk_tile_in;


  -- Tile without DFS: the clock comes from the outside
  -- The BUFG is used to improve timing
  clock_no_pll: if this_has_pll = 0 generate
    --BUFG_inst : BUFG
    --port map (
    --  O => clk_tile,    -- 1-bit output: Clock output
    --  I => clk_tile_in  -- 1-bit input: Clock input
    --);
    clk_tile <= clk_tile_in;
    clk_dfs_out <= '0'; --(others => '0');
    lock_dfs_out <= '1';  -- Generate the lock if there's no pll
  end generate clock_no_pll;

  -- Tile reset: the system reset is synchronized with the local clock
  tile_reset: rstgen
    generic map(acthigh => 0, syncin => 0)
    port map (rstn_sys, clk_tile, lock_rstn_tile, rstn_tile, open);


  --clk_dfs_out <= clk_tile;
  ----------------------------------------------------

  noc_mon_noc_vec <= noc_mon_noc_vec_int;

  -----------------------------------------------------------------------------
  -- JTAG for single tile testing / bypass when test_if_en = 0 (GM change: bypass jtag)
  -----------------------------------------------------------------------------
  noc_acc_stop_in <= test_stop_in_s;
  test_output_port_s <= noc_output_port;
  test_data_void_out_s <= noc_acc_data_void_out;
  test_stop_out_s <= noc_acc_stop_out;
  noc_input_port <= test_input_port_s;
  noc_acc_data_void_in <= test_data_void_in_s;

  tdo <= '0';

  -----------------------------------------------------------------------------
  -- NOC Connections
  ----------------------------------------------------------------------------
  connections_generation: for plane in 0 to num_noc_planes-1 generate
    noc_stop_in_s(plane)         <= noc_acc_stop_in(plane)  & noc_stop_in(plane);
    noc_stop_out(plane)          <= noc_stop_out_s(plane)(3 downto 0);
    noc_acc_stop_out(plane)      <= noc_stop_out_s(plane)(4);
    noc_data_void_in_s(plane)    <= noc_acc_data_void_in(plane) & noc_data_void_in(plane);
    noc_data_void_out(plane)     <= noc_data_void_out_s(plane)(3 downto 0);
    noc_acc_data_void_out(plane) <= noc_data_void_out_s(plane)(4);
  end generate connections_generation;

  sync_noc_set_acc: sync_noc_set
  generic map (
     PORTS    => ROUTER_PORTS,
     HAS_SYNC => HAS_SYNC )
   port map (
     clk                => clk_noc,
     clk_tile           => clk_tile,
     rst                => rstn_noc,
     rst_tile           => rstn_tile,
     CONST_local_x      => this_local_x,
     CONST_local_y      => this_local_y,
     noc_data_n_in     => noc_data_n_in,
     noc_data_s_in     => noc_data_s_in,
     noc_data_w_in     => noc_data_w_in,
     noc_data_e_in     => noc_data_e_in,
     noc_input_port    => noc_input_port,
     noc_data_void_in  => noc_data_void_in_s,
     noc_stop_in       => noc_stop_in_s,
     noc_data_n_out    => noc_data_n_out,
     noc_data_s_out    => noc_data_s_out,
     noc_data_w_out    => noc_data_w_out,
     noc_data_e_out    => noc_data_e_out,
     noc_output_port   => noc_output_port,
     noc_data_void_out => noc_data_void_out_s,
     noc_stop_out      => noc_stop_out_s,
     noc_mon_noc_vec   => noc_mon_noc_vec_int
     );

  tile_acc_1: tile_acc
    generic map (
      this_hls_conf      => this_hls_conf,
      this_device        => this_device,
      this_irq_type      => this_irq_type,
      this_has_l2        => this_has_l2,
      this_has_dco       => 0,
      this_tile_id       => this_tile_id --GM change
    )
    port map (
      rstn_tile          => rstn_tile,
      clk_tile           => clk_tile,
      pad_cfg            => open,
      local_x            => this_local_x,
      local_y            => this_local_y,
      test_output_port   => test_output_port_s,
      test_data_void_out => test_data_void_out_s,
      test_stop_in       => test_stop_out_s,
      test_input_port    => test_input_port_s,
      test_data_void_in  => test_data_void_in_s,
      test_stop_out      => test_stop_in_s,
      noc_mon_noc_vec   => noc_mon_noc_vec_int);
end;
