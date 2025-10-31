------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
------------------------------------------------------------------------------

-- This module creates a chain of three modules:
-- 1) an AHB2AXI converter, which takes the AHB bus coming from the SoC and converts it to an AXI bus with standard SoC datawidth (64-bits);
-- 2) an AXI datawidth converter, which upsizes the 64-bit AXI bus coming from the AHB2AXI module to a 256-bit AXI bus going into HBM;
-- 3) the HBM module.
-- The AHB2AXI and datawidth converter modules are replicated with a number equal to the amount of memory tiles in the SoC. The HBM instead exposes
-- 8 AXI interfaces and it is not modifiable.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.misc.all;
use work.amba.all;
use work.esp_global.all;
use work.stdlib.all;
use work.devices.all;
use work.hbm_pkg.all;

--pragma translate_off
use work.sim.all;
--pragma translate_on

entity hbm_ahb_wrapper is
  generic (
    SIMULATION  : boolean := false;
    hindex      : integer := 0;
    tech        : integer := 0;
    kbytes      : integer := 1;
    pipe        : integer := 0;
    maccsz      : integer := AHBDW;
    endianness  : integer := 0; --0 access as BE
                                --1 access as LE
    scantest    : integer := 0
   );
  port (
    rstn_i              : in  std_ulogic;
    clk_i               : in  std_ulogic;
    hbm_clk_i           : in  std_ulogic;
    dram_stat_catrip_o  : out std_ulogic;
    haddr_vector_i      : in  attribute_vector(0 to CFG_NMEM_TILE-1);
    hmask_vector_i      : in  attribute_vector(0 to CFG_NMEM_TILE-1);
    ahbsi_i             : in  ahb_slv_in_vector_type (0 to CFG_NMEM_TILE-1);
    ahbso_o             : out ahb_slv_out_vector_type(0 to CFG_NMEM_TILE-1)
  );
end;

architecture rtl of hbm_ahb_wrapper is

  constant HBM_AXI_CHANNELS : integer := 8;
  constant ADDR_BITS        : integer := log2ext(kbytes) + 8 - maccsz/64;
  
  -- Buses between the protocol converter (PC) and the datawidth converter (DC)
  signal axi_pc2dc          : axix_mosi_vector(CFG_NMEM_TILE-1 downto 0);
  signal axi_dc2pc          : axi_somi_vector(CFG_NMEM_TILE-1 downto 0);

  -- Buses between the datawidth converter (DC) and the HBM module
  signal axi_dc2hbm         : hbm_axi_mosi_vector(CFG_NMEM_TILE-1 downto 0);
  signal axi_hbm2dc         : hbm_axi_somi_vector(CFG_NMEM_TILE-1 downto 0);
  
  -- 8 buses exposed by the HBM (not all of them may be used)
  signal axi_hbmi           : hbm_axi_mosi_vector(HBM_AXI_CHANNELS-1 downto 0);
  signal axi_hbmo           : hbm_axi_somi_vector(HBM_AXI_CHANNELS-1 downto 0);
  
  signal hconfig_vector     : ahb_config_vector_type(0 to CFG_NMEM_TILE-1);         
  
  begin
  
  -- Generation of the AHB configuration info
  ahb_config_gen: for i in 0 to CFG_NMEM_TILE - 1 generate
    hconfig_vector(i) <= (
      0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_AHBRAM, 0, ADDR_BITS+2+maccsz/64, 0),
      4 => ahb_membar(haddr_vector_i(i), '1', '1', hmask_vector_i(i)),
      others => zero32);
  end generate ahb_config_gen;    
  
  ahb2axi_gen: for i in 0 to CFG_NMEM_TILE-1 generate
    -- AHB2AXI converter module
    ahb2axi_i: ahb2axib
      generic map(
        hindex          => hindex,
        aximid          => 0,  --AXI master transaction ID
        wbuffer_num     => 8,
        rprefetch_num   => 8,
        always_secure   => 1,  --0->not secure; 1->secure
        axi4            => 0,
        ahb_endianness  => endianness,
        endianness_mode => endianness,  --0->BE(AHB)-to-BE(AXI)
                                        --1->BE(AHB)-to-LE(AXI)
        narrow_acc_mode => 0,  --0->each beat in narrow burst
                              --treated as single access
                              --1->narrow burst directly
                              --translated to AXI
                              --supported only in BE-to-BE
        ostand_writes  => 4,
        -- scantest
        scantest       => scantest
        )
      port map (
        rst        => rstn_i,
        clk        => clk_i,
        ahbsi      => ahbsi_i(i),
        ahbso      => ahbso_o(i),
        aximi      => axi_dc2pc(i),
        aximo      => axi_pc2dc(i),
        hconfig    => hconfig_vector(i)
        );
  end generate ahb2axi_gen;
  
  synth_dw_conv: if SIMULATION = false generate
    datawidth_ip_gen_loop: for i in 0 to CFG_NMEM_TILE-1 generate
      -- AXI datawidth converter module    
      dc_axi_i: dwidth_conv_axi_wrapper 
      port map(
        clk_i                  =>  clk_i,
        rstn_i                 =>  rstn_i,
        axi_slv_i              =>  axi_pc2dc(i),
        axi_slv_o              =>  axi_dc2pc(i),
        axi_mst_i              =>  axi_hbm2dc(i),
        axi_mst_o              =>  axi_dc2hbm(i)
        );
    end generate datawidth_ip_gen_loop;
  end generate synth_dw_conv;

  -- Connecting HBM slave channels with several ahb2axi master channels.
  -- Right now, the HBM is implemented with 8 channels.
  -- If the number of mem tiles on the SoC is lower than that, not all of them are connected.
  axi_connection: for i in 0 to HBM_AXI_CHANNELS-1 generate
    valid_channels: if i < CFG_NMEM_TILE generate
      axi_hbmi(i) <= axi_dc2hbm(i);
      axi_hbm2dc(i) <= axi_hbmo(i);
    end generate valid_channels;
    unused_channels: if i >= CFG_NMEM_TILE generate
      axi_hbmi(i) <= hbm_axi_mosi_none;
    end generate unused_channels;
  end generate axi_connection; 
  
  synth_mem: if SIMULATION = false generate
  -- HBM module instance
    hbm_axi_wrapper_i: hbm_axi_wrapper
      generic map(
        N_MEM     => HBM_AXI_CHANNELS   -- Do not change this value!!!
      )
      port map(
        clk_i                    => clk_i,
        rstn_i                   => rstn_i,
        hbm_clk0_i               => hbm_clk_i,
        hbm_clk1_i               => hbm_clk_i,
        axi_slv_i                => axi_hbmi,
        axi_slv_o                => axi_hbmo,
        dram_stat_catrip_o       => dram_stat_catrip_o
      );
  end generate synth_mem;
  
--pragma translate_off
  -- Simulation memory
  sim_mem: if SIMULATION = true generate
    sim_mem_loop: for nmem in 0 to CFG_NMEM_TILE-1 generate
      aximem_i: aximem_sim
        generic map (
          fname    => "ram.srec",
          axibits  => AXIDW,
          rstmode  => 0
          )
        port map (
          clk    => clk_i,
          rst    => rstn_i,
          axisi  => axi_pc2dc(nmem),
          axiso  => axi_dc2pc(nmem)
        );
    end generate sim_mem_loop;
  end generate sim_mem;
--pragma translate_on

end;