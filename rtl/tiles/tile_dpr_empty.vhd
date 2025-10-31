------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    tile_dpr_empty.vhd
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
use work.misc.all;
use work.jtag_pkg.all;
use work.sldacc.all;
use work.nocpackage.all;
use work.cachepackage.all;
use work.tile.all;
use work.coretypes.all;
use work.esp_acc_regmap.all;
use work.socmap.all;
use work.grlib_config.all;
use work.tiles_pkg.all;

entity tile_dpr_empty is
  port (
    rstn_tile                 : in  std_ulogic;
    clk_tile                  : in  std_ulogic;
    -- Pads configuration
    pad_cfg                   : out std_logic_vector(ESP_CSR_PAD_CFG_MSB - ESP_CSR_PAD_CFG_LSB downto 0);
    -- NOC
    local_x                   : out local_yx;
    local_y                   : out local_yx;
    noc_mon_noc_vec_dpr       : in  std_logic_vector(MON_NOC_VEC_SIZE-1 downto 0);
    test_output_port_dpr      : in  std_logic_vector(num_noc_planes*NOC_FLIT_SIZE-1 downto 0);
    test_data_void_out        : in  std_ulogic_vector(num_noc_planes-1 downto 0);
    test_stop_in              : in  std_ulogic_vector(num_noc_planes-1 downto 0);
    test_input_port_dpr       : out std_logic_vector(num_noc_planes*NOC_FLIT_SIZE-1 downto 0);
    test_data_void_in         : out std_ulogic_vector(num_noc_planes-1 downto 0);
    test_stop_out             : out std_ulogic_vector(num_noc_planes-1 downto 0));

end;

architecture rtl of tile_dpr_empty is
attribute keep_hierarchy : string;
attribute keep_hierarchy of rtl : architecture is "yes";

  --I/O to be converted into vectors
  signal test_output_port      : noc_flit_vector;
  signal test_input_port       : noc_flit_vector;
  signal noc_mon_noc_vec       : monitor_noc_vector(num_noc_planes-1 downto 0);

begin

  --Compound signals cannot exists at the interface of a reconfigurable partition. It seems to be a limitation of Vivado.
  --For this reason, all compound signals are converted into vectors.
  test_output_port       <= stdlogicvector2nocflitvector(test_output_port_dpr);
  test_input_port_dpr    <= nocflitvector2stdlogicvector(test_input_port);
  noc_mon_noc_vec        <= stdlogicvector2monitornocvector(noc_mon_noc_vec_dpr);

  tile_empty_1: tile_empty
    generic map (
      this_has_dco => 0)
    port map (
      rstn_sys           => rstn_tile,
      clk_sys            => clk_tile,
      pad_cfg            => pad_cfg,
      local_x            => local_x,
      local_y            => local_y,
      test_output_port   => test_output_port,
      test_data_void_out => test_data_void_out,
      test_stop_in       => test_stop_in,
      test_input_port    => test_input_port,
      test_data_void_in  => test_data_void_in,
      test_stop_out      => test_stop_out,
      noc_mon_noc_vec   => noc_mon_noc_vec);
end;


