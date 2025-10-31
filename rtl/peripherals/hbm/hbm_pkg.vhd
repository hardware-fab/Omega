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


library ieee;
use ieee.std_logic_1164.all;

use work.misc.all;
use work.amba.all;
use work.esp_global.all;

package hbm_pkg is

  -- Axi types with specific HBM size
  
  constant AXI_HBM_ID_WIDTH      :    integer   := 6;
  constant AXI_HBM_ADDR_WIDTH    :    integer   := 34;
  constant AXI_HBM_DATA_WIDTH    :    integer   := 256;


  type hbm_axi_aw_mosi_type is record      -- Master Output Slave Input
    id     : std_logic_vector (AXI_HBM_ID_WIDTH-1 downto 0);
    addr   : std_logic_vector (AXI_HBM_ADDR_WIDTH - 1 downto 0);
    len    : std_logic_vector (3 downto 0);
    size   : std_logic_vector (2 downto 0);
    burst  : std_logic_vector (1 downto 0);
    --lock   : std_logic_vector (1 downto 0);
    cache  : std_logic_vector (3 downto 0);
    prot   : std_logic_vector (2 downto 0);
    valid  : std_logic;
    qos    : std_logic_vector (3 downto 0);
    atop   : std_logic_vector (5 downto 0);
    region : std_logic_vector (3 downto 0);
  end record;
  type hbm_axi_aw_somi_type is record -- Slave Output Master Input
    ready  : std_logic;
  end record;
  type hbm_axi_w_mosi_type is record -- Master Output Slave Input
    data    : std_logic_vector (AXI_HBM_DATA_WIDTH-1 downto 0);
    strb    : std_logic_vector (AXI_HBM_DATA_WIDTH/8-1 downto 0);
    last    : std_logic;
    valid   : std_logic;
  end record;
  type hbm_axi_w_somi_type is record -- Slave Output Master Input
    ready   : std_logic;
  end record;
  type hbm_axi_ar_mosi_type is record -- Master Output Slave Input
    id     : std_logic_vector (AXI_HBM_ID_WIDTH-1 downto 0);
    addr   : std_logic_vector (AXI_HBM_ADDR_WIDTH - 1 downto 0);
    len    : std_logic_vector (3 downto 0);
    size   : std_logic_vector (2 downto 0);
    burst  : std_logic_vector (1 downto 0);
    --lock   : std_logic_vector (1 downto 0);
    cache  : std_logic_vector (3 downto 0);
    prot   : std_logic_vector (2 downto 0);
    valid  : std_logic;
    qos    : std_logic_vector (3 downto 0);
    region : std_logic_vector (3 downto 0);
  end record;
  type hbm_axi_ar_somi_type is record -- Slave Output Master Input
    ready  : std_logic;
  end record;
  type hbm_axi_r_mosi_type is record -- Master Output Slave Input
    ready   : std_logic;
  end record;
  type hbm_axi_r_somi_type is record -- Slave Output Master Input
    id    : std_logic_vector (AXI_HBM_ID_WIDTH-1 downto 0);
    data  : std_logic_vector (AXI_HBM_DATA_WIDTH-1 downto 0);
    resp  : std_logic_vector (1 downto 0);
    last  : std_logic;
    valid : std_logic;
  end record;
  type hbm_axi_b_mosi_type is record -- Master Output Slave Input
    ready   : std_logic;
  end record;
  type hbm_axi_b_somi_type is record -- Slave Output Master Input
    id    : std_logic_vector (AXI_HBM_ID_WIDTH-1 downto 0);
    resp  : std_logic_vector (1 downto 0);
    valid : std_logic;
  end record;
  type hbm_axi_mosi_type is record -- Master Output Slave Input
    aw  : hbm_axi_aw_mosi_type;
    w   : hbm_axi_w_mosi_type;
    b   : hbm_axi_b_mosi_type;
    ar  : hbm_axi_ar_mosi_type;
    r   : hbm_axi_r_mosi_type;
  end record;
  type hbm_axi_somi_type is record -- Slave Output Master Input
    aw  : hbm_axi_aw_somi_type;
    w   : hbm_axi_w_somi_type;
    b   : hbm_axi_b_somi_type;
    ar  : hbm_axi_ar_somi_type;
    r   : hbm_axi_r_somi_type;
  end record;
  type hbm_axi_mosi_vector is array (natural range <>) of hbm_axi_mosi_type;
  type hbm_axi_somi_vector is array (natural range <>) of hbm_axi_somi_type;

  constant hbm_axi_aw_mosi_none : hbm_axi_aw_mosi_type := (
    id     => (others => '0'),
    addr   => (others => '0'),
    len    => (others => '0'),
    size   => (others => '0'),
    burst  => (others => '0'),
    --lock   => '0',
    cache  => (others => '0'),
    prot   => (others => '0'),
    valid  => '0',
    qos    => (others => '0'),
    atop   => (others => '0'),
    region => (others => '0')
  );
  constant hbm_axi_aw_somi_none : hbm_axi_aw_somi_type := (ready => '0');
  constant hbm_axi_w_mosi_none : hbm_axi_w_mosi_type := (
    data  => (others => '0'),
    strb  => (others => '0'),
    last  => '0',
    valid => '0'
  );
  constant hbm_axi_w_somi_none : hbm_axi_w_somi_type := (ready => '0');
  constant hbm_axi_ar_mosi_none : hbm_axi_ar_mosi_type := (
    id     => (others => '0'),
    addr   => (others => '0'),
    len    => (others => '0'),
    size   => (others => '0'),
    burst  => (others => '0'),
    --lock   => '0',
    cache  => (others => '0'),
    prot   => (others => '0'),
    valid  => '0',
    qos    => (others => '0'),
    region => (others => '0')
  );
  constant hbm_axi_ar_somi_none : hbm_axi_ar_somi_type := (ready => '0');
  constant hbm_axi_r_somi_none : hbm_axi_r_somi_type := (
    id => (others => '0'),
    data => (others => '0'),
    resp => (others => '0'),
    last => '0',
    valid => '0'
  );
  constant hbm_axi_r_mosi_none : hbm_axi_r_mosi_type := (ready => '0');
  constant hbm_axi_b_somi_none : hbm_axi_b_somi_type := (
    id => (others => '0'),
    resp => (others => '0'),
    valid => '0'
  );
  constant hbm_axi_b_mosi_none : hbm_axi_b_mosi_type := (ready => '0');
  constant hbm_axi_mosi_none : hbm_axi_mosi_type := (
    aw => hbm_axi_aw_mosi_none,
    w  => hbm_axi_w_mosi_none,
    ar => hbm_axi_ar_mosi_none,
    r  => hbm_axi_r_mosi_none,
    b  => hbm_axi_b_mosi_none
  );
  constant hbm_axi_somi_none : hbm_axi_somi_type := (
    aw => hbm_axi_aw_somi_none,
    w  => hbm_axi_w_somi_none,
    ar => hbm_axi_ar_somi_none,
    r  => hbm_axi_r_somi_none,
    b  => hbm_axi_b_somi_none
  );

  component hbm_ahb_wrapper is
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
  end component hbm_ahb_wrapper;
  
  component hbm_axi_wrapper is
    generic (
      N_MEM     : natural               := 8   -- Do not change this value!!!
    );
    port (
      clk_i                    : in  std_ulogic;
      rstn_i                   : in  std_ulogic;
      hbm_clk0_i               : in  std_logic;
      hbm_clk1_i               : in  std_logic;
      axi_slv_i                : in  hbm_axi_mosi_vector(N_MEM-1 downto 0);
      axi_slv_o                : out hbm_axi_somi_vector(N_MEM-1 downto 0);
      dram_stat_catrip_o       : out std_ulogic
      );
  end component hbm_axi_wrapper;
  
  component dwidth_conv_axi_wrapper is
    port (
      clk_i                    : in  std_ulogic;
      rstn_i                   : in  std_ulogic;
      axi_slv_i                : in  axix_mosi_type;
      axi_slv_o                : out axi_somi_type;
      axi_mst_i                : in  hbm_axi_somi_type;
      axi_mst_o                : out hbm_axi_mosi_type
      );
  end component dwidth_conv_axi_wrapper;
end;