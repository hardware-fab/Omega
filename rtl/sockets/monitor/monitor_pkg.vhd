------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    monitor_pkg.vhd
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

use work.esp_global.all;

use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;

use work.gencomp.all;
use work.genacc.all;

use work.coretypes.all;
use work.esp_acc_regmap.all;

package monitor_pkg is

  type monitor_ddr_type is record
    clk           : std_ulogic;
    word_transfer : std_ulogic;
  end record;

  type monitor_mem_type is record
    clk              : std_ulogic;
    coherent_req     : std_ulogic;
    coherent_fwd     : std_ulogic;
    coherent_rsp_rcv : std_ulogic;
    coherent_rsp_snd : std_ulogic;
    dma_req          : std_ulogic;
    dma_rsp          : std_ulogic;
    coherent_dma_req : std_ulogic;
    coherent_dma_rsp : std_ulogic;
  end record;

  type monitor_noc_type is record
    clk         : std_ulogic;
    tile_inject : std_ulogic;
    tile_eject  : std_logic;
    queue_full  : std_logic_vector(4 downto 0);
  end record;

  type monitor_cache_type is record
    clk  : std_ulogic;
    hit  : std_ulogic;
    miss : std_ulogic;
  end record;
  constant MON_CACHE_SIZE : integer := 3;

  constant MON_ACC_RTT_SIZE : integer := 16;

  type monitor_acc_type is record
    clk            : std_ulogic;
    go             : std_ulogic;
    run            : std_ulogic;
    done           : std_ulogic;
    burst          : std_ulogic;
    roundtrip_time : std_logic_vector(MON_ACC_RTT_SIZE-1 downto 0);
  end record;
  constant MON_ACC_SIZE : integer := 5+MON_ACC_RTT_SIZE;

  type monitor_dvfs_type is record
    clk       : std_ulogic;
    vf        : std_logic_vector(3 downto 0);
    acc_idle  : std_ulogic;
    traffic   : std_ulogic;
    burst     : std_ulogic;
    transient : std_ulogic;
  end record;
  constant MON_DVFS_SIZE : integer := 9;

  type monitor_ddr_vector is array (natural range <>) of monitor_ddr_type;

  type monitor_noc_vector is array (natural range <>) of monitor_noc_type;
  constant MON_NOC_VEC_SIZE : integer := num_noc_planes*8;

  type monitor_noc_matrix is array (natural range <>, natural range <>) of monitor_noc_type;

  --GM change: vector and matrix for the injection/ejection type
  --type monitor_transit_vector is array (natural range <>) of monitor_transit_type;
  --type monitor_transit_matrix is array (natural range <>, natural range <>) of monitor_transit_type;

  type monitor_mem_vector is array (natural range <>) of monitor_mem_type;

  type monitor_cache_vector is array (natural range <>) of monitor_cache_type;

  type monitor_acc_vector is array (natural range <>) of monitor_acc_type;

  type monitor_dvfs_vector is array (natural range <>) of monitor_dvfs_type;


  constant monitor_noc_none : monitor_noc_type := (
    clk         => '0',
    tile_inject => '0',
    tile_eject  => '0',
    queue_full  => (others => '0')
    );

  --GM change: null value for the injection/ejection type
  --constant monitor_transit_none : monitor_transit_type := (
  --  clk         => '0',
  --  tile_inject => '0',
  --  tile_eject  => '0'
  --  );

  constant monitor_acc_none : monitor_acc_type := (
    clk   => '0',
    go    => '0',
    run   => '0',
    done  => '0',
    burst => '0',
    roundtrip_time => (others => '0')
    );

  constant monitor_cache_none : monitor_cache_type := (
    clk  => '0',
    hit  => '0',
    miss => '0'
    );

  constant monitor_dvfs_none : monitor_dvfs_type := (
    clk       => '0',
    vf        => (others => '0'),
    acc_idle  => '0',
    traffic   => '0',
    burst     => '0',
    transient => '0'
    );

  constant monitor_ddr_none : monitor_ddr_type := (
    clk           => '0',
    word_transfer => '0'
    );

  constant monitor_mem_none : monitor_mem_type := (
    clk              => '0',
    coherent_req     => '0',
    coherent_fwd     => '0',
    coherent_rsp_rcv => '0',
    coherent_rsp_snd => '0',
    dma_req          => '0',
    dma_rsp          => '0',
    coherent_dma_req => '0',
    coherent_dma_rsp => '0'
    );

  component monitor
    generic (
      memtech                : integer;
      mmi64_width            : integer;
      ddrs_num               : integer;
      slms_num               : integer;
      nocs_num               : integer;
      tiles_num              : integer;
      accelerators_num       : integer;
      l2_num                 : integer;
      llc_num                : integer;
      mon_ddr_en             : integer;
      mon_noc_tile_inject_en : integer;
      mon_noc_queues_full_en : integer;
      mon_acc_en             : integer;
      mon_mem_en             : integer;
      mon_l2_en              : integer;
      mon_llc_en             : integer;
      mon_dvfs_en            : integer);
    port (
      profpga_clk0_p  : in  std_logic;
      profpga_clk0_n  : in  std_logic;
      profpga_sync0_p : in  std_logic;
      profpga_sync0_n : in  std_logic;
      dmbi_h2f        : in  std_logic_vector(19 downto 0);
      dmbi_f2h        : out std_logic_vector(19 downto 0);
      user_rstn       : in  std_logic;
      mon_ddr         : in  monitor_ddr_vector(0 to ddrs_num-1);
      mon_noc         : in  monitor_noc_matrix(0 to nocs_num-1, 0 to tiles_num-1);
      mon_acc         : in  monitor_acc_vector(0 to relu(accelerators_num-1));
      mon_mem         : in  monitor_mem_vector(0 to ddrs_num+slms_num-1);
      mon_l2          : in  monitor_cache_vector(0 to relu(l2_num-1));
      mon_llc         : in  monitor_cache_vector(0 to relu(llc_num-1));
      mon_dvfs        : in  monitor_dvfs_vector(0 to tiles_num-1);
      user_rst_o      : out std_logic --GM change: need this reset as the main reset
    );
  end component;

  --These functions convert the monitor signals into standard logic vectors, and viceversa.
  --They are needed at the interface of the reconfigurable partitions, where custom types are not allowed.

  --Conversion of monitor_noc_vector

  function monitornocvector2stdlogicvector (
    data_i : monitor_noc_vector)
    return std_logic_vector;

  function stdlogicvector2monitornocvector (
    data_i : std_logic_vector(MON_NOC_VEC_SIZE-1 downto 0))
    return monitor_noc_vector;


  --Conversion of monitor_dvfs_type

  function monitordvfstype2stdlogicvector (
    data_i : monitor_dvfs_type)
    return std_logic_vector;

  function stdlogicvector2monitordvfstype (
    data_i : std_logic_vector(MON_DVFS_SIZE-1 downto 0))
    return monitor_dvfs_type;


  --Conversion of monitor_dvfs_type

  function monitoracctype2stdlogicvector (
    data_i : monitor_acc_type)
    return std_logic_vector;

  function stdlogicvector2monitoracctype (
    data_i : std_logic_vector(MON_ACC_SIZE-1 downto 0))
    return monitor_acc_type;


  --Conversion of monitor_dvfs_type

  function monitorcachetype2stdlogicvector (
    data_i : monitor_cache_type)
    return std_logic_vector;

  function stdlogicvector2monitorcachetype (
    data_i : std_logic_vector(MON_CACHE_SIZE-1 downto 0))
    return monitor_cache_type;


end monitor_pkg;

package body monitor_pkg is

  --These functions convert the monitor signals into standard logic vectors, and viceversa.
  --They are needed at the interface of the reconfigurable partitions, where custom types are not allowed.

  --Conversion of monitor_noc_vector

  function monitornocvector2stdlogicvector (
    data_i : monitor_noc_vector)
    return std_logic_vector is
    variable vector : std_logic_vector(MON_NOC_VEC_SIZE-1 downto 0);
    variable count : integer := 0;
  begin
    count := 0;
    for i in 0 to num_noc_planes-1 loop
      vector(count + 0) := data_i(i).clk;
      vector(count + 1) := data_i(i).tile_inject;
      vector(count + 2) := data_i(i).tile_eject;
      vector(count + 7 downto count + 3) := data_i(i).queue_full;
      count := count + 8;
    end loop;
    return vector;
  end monitornocvector2stdlogicvector;

  function stdlogicvector2monitornocvector (
    data_i : std_logic_vector(MON_NOC_VEC_SIZE-1 downto 0))
    return monitor_noc_vector is
    variable mon_vector : monitor_noc_vector(num_noc_planes-1 downto 0);
    variable count : integer := 0;
  begin
    count := 0;
    for i in 0 to num_noc_planes-1 loop
      mon_vector(i).clk := data_i(count + 0);
      mon_vector(i).tile_inject := data_i(count + 1);
      mon_vector(i).tile_eject := data_i(count + 2);
      mon_vector(i).queue_full := data_i(count + 7 downto count + 3);
      count := count + 8;
    end loop;
    return mon_vector;
  end stdlogicvector2monitornocvector;


  --Conversion of monitor_dvfs_type

  function monitordvfstype2stdlogicvector (
    data_i : monitor_dvfs_type)
    return std_logic_vector is
    variable vector : std_logic_vector(MON_DVFS_SIZE-1 downto 0);
    variable count : integer := 0;
  begin
    count := 0;
    vector(count) := data_i.clk;
    count := count + 1;
    vector(count + 3 downto count) := data_i.vf;
    count := count + 4;
    vector(count) := data_i.acc_idle;
    count := count + 1;
    vector(count) := data_i.traffic;
    count := count + 1;
    vector(count) := data_i.burst;
    count := count + 1;
    vector(count) := data_i.transient;
    count := count + 1;
    return vector;
  end monitordvfstype2stdlogicvector;

  function stdlogicvector2monitordvfstype (
    data_i : std_logic_vector(MON_DVFS_SIZE-1 downto 0))
    return monitor_dvfs_type is
    variable mon_var : monitor_dvfs_type;
    variable count : integer := 0;
  begin
    count := 0;
    mon_var.clk := data_i(count);
    count := count + 1;
    mon_var.vf := data_i(count + 3 downto count);
    count := count + 4;
    mon_var.acc_idle := data_i(count);
    count := count + 1;
    mon_var.traffic := data_i(count);
    count := count + 1;
    mon_var.burst := data_i(count);
    count := count + 1;
    mon_var.transient := data_i(count);
    count := count + 1;
    return mon_var;
  end stdlogicvector2monitordvfstype;


  --Conversion of monitor_dvfs_type

  function monitoracctype2stdlogicvector (
    data_i : monitor_acc_type)
    return std_logic_vector is
    variable vector : std_logic_vector(MON_ACC_SIZE-1 downto 0);
    variable count : integer := 0;
  begin
    count := 0;
    vector(count) := data_i.clk;
    count := count + 1;
    vector(count) := data_i.go;
    count := count + 1;
    vector(count) := data_i.run;
    count := count + 1;
    vector(count) := data_i.done;
    count := count + 1;
    vector(count) := data_i.burst;
    count := count + 1;
    vector(count + MON_ACC_RTT_SIZE - 1 downto count) := data_i.roundtrip_time;
    return vector;
  end monitoracctype2stdlogicvector;

  function stdlogicvector2monitoracctype (
    data_i : std_logic_vector(MON_ACC_SIZE-1 downto 0))
    return monitor_acc_type is
    variable mon_var : monitor_acc_type;
    variable count : integer := 0;
  begin
    count := 0;
    mon_var.clk := data_i(count);
    count := count + 1;
    mon_var.go := data_i(count);
    count := count + 1;
    mon_var.run := data_i(count);
    count := count + 1;
    mon_var.done := data_i(count);
    count := count + 1;
    mon_var.burst := data_i(count);
    count := count + 1;
    mon_var.roundtrip_time := data_i(count + MON_ACC_RTT_SIZE - 1 downto count);
    return mon_var;
  end stdlogicvector2monitoracctype;


  --Conversion of monitor_dvfs_type

  function monitorcachetype2stdlogicvector (
    data_i : monitor_cache_type)
    return std_logic_vector is
    variable vector : std_logic_vector(MON_CACHE_SIZE-1 downto 0);
    variable count : integer := 0;
  begin
    count := 0;
    vector(count) := data_i.clk;
    count := count + 1;
    vector(count) := data_i.hit;
    count := count + 1;
    vector(count) := data_i.miss;
    return vector;
  end monitorcachetype2stdlogicvector;

  function stdlogicvector2monitorcachetype (
    data_i : std_logic_vector(MON_CACHE_SIZE-1 downto 0))
    return monitor_cache_type is
    variable mon_var : monitor_cache_type;
    variable count : integer := 0;
  begin
    count := 0;
    mon_var.clk := data_i(count);
    count := count + 1;
    mon_var.hit := data_i(count);
    count := count + 1;
    mon_var.miss := data_i(count);
    return mon_var;
  end stdlogicvector2monitorcachetype;


end monitor_pkg;
