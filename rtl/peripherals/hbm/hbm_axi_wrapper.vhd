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
use work.amba.all;
use work.hbm_pkg.all;

entity hbm_axi_wrapper is
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
end hbm_axi_wrapper;

architecture rtl of hbm_axi_wrapper is

  signal dram_stat_catrip_0, dram_stat_catrip_1 : std_ulogic;

  component hbm_interface
    port (
      HBM_REF_CLK_0        : in std_logic;
      HBM_REF_CLK_1        : in std_logic;
      
      AXI_00_ACLK          : in  std_logic;
      AXI_00_ARESET_N      : in  std_logic;
      AXI_00_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_00_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_00_ARID          : in  std_logic_vector(5 downto 0);
      AXI_00_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_00_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_00_ARVALID       : in  std_logic;
      AXI_00_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_00_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_00_AWID          : in  std_logic_vector(5 downto 0);
      AXI_00_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_00_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_00_AWVALID       : in  std_logic;
      AXI_00_RREADY        : in  std_logic;
      AXI_00_BREADY        : in  std_logic;
      AXI_00_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_00_WLAST         : in  std_logic;
      AXI_00_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_00_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_00_WVALID        : in  std_logic;
      AXI_00_ARREADY       : out std_logic;
      AXI_00_AWREADY       : out std_logic;
      AXI_00_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_00_RDATA         : out std_logic_vector(255 downto 0);
      AXI_00_RID           : out std_logic_vector(5 downto 0);
      AXI_00_RLAST         : out std_logic;
      AXI_00_RRESP         : out std_logic_vector(1 downto 0);
      AXI_00_RVALID        : out std_logic;
      AXI_00_WREADY        : out std_logic;
      AXI_00_BID           : out std_logic_vector(5 downto 0);
      AXI_00_BRESP         : out std_logic_vector(1 downto 0);
      AXI_00_BVALID        : out std_logic;

      AXI_04_ACLK          : in  std_logic;
      AXI_04_ARESET_N      : in  std_logic;
      AXI_04_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_04_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_04_ARID          : in  std_logic_vector(5 downto 0);
      AXI_04_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_04_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_04_ARVALID       : in  std_logic;
      AXI_04_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_04_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_04_AWID          : in  std_logic_vector(5 downto 0);
      AXI_04_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_04_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_04_AWVALID       : in  std_logic;
      AXI_04_RREADY        : in  std_logic;
      AXI_04_BREADY        : in  std_logic;
      AXI_04_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_04_WLAST         : in  std_logic;
      AXI_04_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_04_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_04_WVALID        : in  std_logic;
      AXI_04_ARREADY       : out std_logic;
      AXI_04_AWREADY       : out std_logic;
      AXI_04_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_04_RDATA         : out std_logic_vector(255 downto 0);
      AXI_04_RID           : out std_logic_vector(5 downto 0);
      AXI_04_RLAST         : out std_logic;
      AXI_04_RRESP         : out std_logic_vector(1 downto 0);
      AXI_04_RVALID        : out std_logic;
      AXI_04_WREADY        : out std_logic;
      AXI_04_BID           : out std_logic_vector(5 downto 0);
      AXI_04_BRESP         : out std_logic_vector(1 downto 0);
      AXI_04_BVALID        : out std_logic;
      
      AXI_08_ACLK          : in  std_logic;
      AXI_08_ARESET_N      : in  std_logic;
      AXI_08_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_08_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_08_ARID          : in  std_logic_vector(5 downto 0);
      AXI_08_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_08_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_08_ARVALID       : in  std_logic;
      AXI_08_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_08_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_08_AWID          : in  std_logic_vector(5 downto 0);
      AXI_08_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_08_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_08_AWVALID       : in  std_logic;
      AXI_08_RREADY        : in  std_logic;
      AXI_08_BREADY        : in  std_logic;
      AXI_08_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_08_WLAST         : in  std_logic;
      AXI_08_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_08_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_08_WVALID        : in  std_logic;
      AXI_08_ARREADY       : out std_logic;
      AXI_08_AWREADY       : out std_logic;
      AXI_08_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_08_RDATA         : out std_logic_vector(255 downto 0);
      AXI_08_RID           : out std_logic_vector(5 downto 0);
      AXI_08_RLAST         : out std_logic;
      AXI_08_RRESP         : out std_logic_vector(1 downto 0);
      AXI_08_RVALID        : out std_logic;
      AXI_08_WREADY        : out std_logic;
      AXI_08_BID           : out std_logic_vector(5 downto 0);
      AXI_08_BRESP         : out std_logic_vector(1 downto 0);
      AXI_08_BVALID        : out std_logic;
      
      AXI_12_ACLK          : in  std_logic;
      AXI_12_ARESET_N      : in  std_logic;
      AXI_12_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_12_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_12_ARID          : in  std_logic_vector(5 downto 0);
      AXI_12_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_12_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_12_ARVALID       : in  std_logic;
      AXI_12_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_12_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_12_AWID          : in  std_logic_vector(5 downto 0);
      AXI_12_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_12_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_12_AWVALID       : in  std_logic;
      AXI_12_RREADY        : in  std_logic;
      AXI_12_BREADY        : in  std_logic;
      AXI_12_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_12_WLAST         : in  std_logic;
      AXI_12_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_12_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_12_WVALID        : in  std_logic;
      AXI_12_ARREADY       : out std_logic;
      AXI_12_AWREADY       : out std_logic;
      AXI_12_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_12_RDATA         : out std_logic_vector(255 downto 0);
      AXI_12_RID           : out std_logic_vector(5 downto 0);
      AXI_12_RLAST         : out std_logic;
      AXI_12_RRESP         : out std_logic_vector(1 downto 0);
      AXI_12_RVALID        : out std_logic;
      AXI_12_WREADY        : out std_logic;
      AXI_12_BID           : out std_logic_vector(5 downto 0);
      AXI_12_BRESP         : out std_logic_vector(1 downto 0);
      AXI_12_BVALID        : out std_logic;
      
      AXI_16_ACLK          : in  std_logic;
      AXI_16_ARESET_N      : in  std_logic;
      AXI_16_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_16_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_16_ARID          : in  std_logic_vector(5 downto 0);
      AXI_16_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_16_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_16_ARVALID       : in  std_logic;
      AXI_16_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_16_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_16_AWID          : in  std_logic_vector(5 downto 0);
      AXI_16_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_16_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_16_AWVALID       : in  std_logic;
      AXI_16_RREADY        : in  std_logic;
      AXI_16_BREADY        : in  std_logic;
      AXI_16_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_16_WLAST         : in  std_logic;
      AXI_16_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_16_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_16_WVALID        : in  std_logic;
      AXI_16_ARREADY       : out std_logic;
      AXI_16_AWREADY       : out std_logic;
      AXI_16_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_16_RDATA         : out std_logic_vector(255 downto 0);
      AXI_16_RID           : out std_logic_vector(5 downto 0);
      AXI_16_RLAST         : out std_logic;
      AXI_16_RRESP         : out std_logic_vector(1 downto 0);
      AXI_16_RVALID        : out std_logic;
      AXI_16_WREADY        : out std_logic;
      AXI_16_BID           : out std_logic_vector(5 downto 0);
      AXI_16_BRESP         : out std_logic_vector(1 downto 0);
      AXI_16_BVALID        : out std_logic;
      
      AXI_20_ACLK          : in  std_logic;
      AXI_20_ARESET_N      : in  std_logic;
      AXI_20_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_20_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_20_ARID          : in  std_logic_vector(5 downto 0);
      AXI_20_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_20_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_20_ARVALID       : in  std_logic;
      AXI_20_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_20_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_20_AWID          : in  std_logic_vector(5 downto 0);
      AXI_20_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_20_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_20_AWVALID       : in  std_logic;
      AXI_20_RREADY        : in  std_logic;
      AXI_20_BREADY        : in  std_logic;
      AXI_20_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_20_WLAST         : in  std_logic;
      AXI_20_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_20_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_20_WVALID        : in  std_logic;
      AXI_20_ARREADY       : out std_logic;
      AXI_20_AWREADY       : out std_logic;
      AXI_20_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_20_RDATA         : out std_logic_vector(255 downto 0);
      AXI_20_RID           : out std_logic_vector(5 downto 0);
      AXI_20_RLAST         : out std_logic;
      AXI_20_RRESP         : out std_logic_vector(1 downto 0);
      AXI_20_RVALID        : out std_logic;
      AXI_20_WREADY        : out std_logic;
      AXI_20_BID           : out std_logic_vector(5 downto 0);
      AXI_20_BRESP         : out std_logic_vector(1 downto 0);
      AXI_20_BVALID        : out std_logic;
      
      AXI_24_ACLK          : in  std_logic;
      AXI_24_ARESET_N      : in  std_logic;
      AXI_24_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_24_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_24_ARID          : in  std_logic_vector(5 downto 0);
      AXI_24_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_24_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_24_ARVALID       : in  std_logic;
      AXI_24_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_24_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_24_AWID          : in  std_logic_vector(5 downto 0);
      AXI_24_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_24_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_24_AWVALID       : in  std_logic;
      AXI_24_RREADY        : in  std_logic;
      AXI_24_BREADY        : in  std_logic;
      AXI_24_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_24_WLAST         : in  std_logic;
      AXI_24_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_24_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_24_WVALID        : in  std_logic;
      AXI_24_ARREADY       : out std_logic;
      AXI_24_AWREADY       : out std_logic;
      AXI_24_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_24_RDATA         : out std_logic_vector(255 downto 0);
      AXI_24_RID           : out std_logic_vector(5 downto 0);
      AXI_24_RLAST         : out std_logic;
      AXI_24_RRESP         : out std_logic_vector(1 downto 0);
      AXI_24_RVALID        : out std_logic;
      AXI_24_WREADY        : out std_logic;
      AXI_24_BID           : out std_logic_vector(5 downto 0);
      AXI_24_BRESP         : out std_logic_vector(1 downto 0);
      AXI_24_BVALID        : out std_logic;
      
      AXI_28_ACLK          : in  std_logic;
      AXI_28_ARESET_N      : in  std_logic;
      AXI_28_ARADDR        : in  std_logic_vector(33 downto 0);
      AXI_28_ARBURST       : in  std_logic_vector(1 downto 0);
      AXI_28_ARID          : in  std_logic_vector(5 downto 0);
      AXI_28_ARLEN         : in  std_logic_vector(3 downto 0);
      AXI_28_ARSIZE        : in  std_logic_vector(2 downto 0);
      AXI_28_ARVALID       : in  std_logic;
      AXI_28_AWADDR        : in  std_logic_vector(33 downto 0);
      AXI_28_AWBURST       : in  std_logic_vector(1 downto 0);
      AXI_28_AWID          : in  std_logic_vector(5 downto 0);
      AXI_28_AWLEN         : in  std_logic_vector(3 downto 0);
      AXI_28_AWSIZE        : in  std_logic_vector(2 downto 0);
      AXI_28_AWVALID       : in  std_logic;
      AXI_28_RREADY        : in  std_logic;
      AXI_28_BREADY        : in  std_logic;
      AXI_28_WDATA         : in  std_logic_vector(255 downto 0);
      AXI_28_WLAST         : in  std_logic;
      AXI_28_WSTRB         : in  std_logic_vector(31 downto 0);
      AXI_28_WDATA_PARITY  : in  std_logic_vector(31 downto 0);
      AXI_28_WVALID        : in  std_logic;
      AXI_28_ARREADY       : out std_logic;
      AXI_28_AWREADY       : out std_logic;
      AXI_28_RDATA_PARITY  : out std_logic_vector(31 downto 0);
      AXI_28_RDATA         : out std_logic_vector(255 downto 0);
      AXI_28_RID           : out std_logic_vector(5 downto 0);
      AXI_28_RLAST         : out std_logic;
      AXI_28_RRESP         : out std_logic_vector(1 downto 0);
      AXI_28_RVALID        : out std_logic;
      AXI_28_WREADY        : out std_logic;
      AXI_28_BID           : out std_logic_vector(5 downto 0);
      AXI_28_BRESP         : out std_logic_vector(1 downto 0);
      AXI_28_BVALID        : out std_logic;
      
      APB_0_PCLK           : in  std_logic;
      APB_0_PRESET_N       : in  std_logic;
      APB_1_PCLK           : in  std_logic;
      APB_1_PRESET_N       : in  std_logic;
      apb_complete_0       : out std_logic;
      apb_complete_1       : out std_logic;
      DRAM_0_STAT_CATTRIP  : out std_logic;
      DRAM_0_STAT_TEMP     : out std_logic_vector(6 downto 0);
      DRAM_1_STAT_CATTRIP  : out std_logic;
      DRAM_1_STAT_TEMP     : out std_logic_vector(6 downto 0)
      );
  end component;

begin

  -- Switch off the board if one of the HBM is overheating
  dram_stat_catrip_o <= dram_stat_catrip_0 or dram_stat_catrip_1;

  -- Instantiation of the HBM module
  hbm_interface_i: hbm_interface
    port map (
      HBM_REF_CLK_0        => hbm_clk0_i,
      HBM_REF_CLK_1        => hbm_clk1_i,

      AXI_00_ACLK          => clk_i,
      AXI_00_ARESET_N      => rstn_i,
      AXI_00_ARADDR        => axi_slv_i(0).ar.addr,
      AXI_00_ARBURST       => axi_slv_i(0).ar.burst,
      AXI_00_ARID          => axi_slv_i(0).ar.id,
      AXI_00_ARLEN         => axi_slv_i(0).ar.len,
      AXI_00_ARSIZE        => axi_slv_i(0).ar.size,
      AXI_00_ARVALID       => axi_slv_i(0).ar.valid,
      AXI_00_AWADDR        => axi_slv_i(0).aw.addr,
      AXI_00_AWBURST       => axi_slv_i(0).aw.burst,
      AXI_00_AWID          => axi_slv_i(0).aw.id,
      AXI_00_AWLEN         => axi_slv_i(0).aw.len,
      AXI_00_AWSIZE        => axi_slv_i(0).aw.size,
      AXI_00_AWVALID       => axi_slv_i(0).aw.valid,
      AXI_00_RREADY        => axi_slv_i(0).r.ready,
      AXI_00_BREADY        => axi_slv_i(0).b.ready,
      AXI_00_WDATA         => axi_slv_i(0).w.data,
      AXI_00_WLAST         => axi_slv_i(0).w.last,
      AXI_00_WSTRB         => axi_slv_i(0).w.strb,
      AXI_00_WDATA_PARITY  => (others => '1'),
      AXI_00_WVALID        => axi_slv_i(0).w.valid,
      AXI_00_ARREADY       => axi_slv_o(0).ar.ready,
      AXI_00_AWREADY       => axi_slv_o(0).aw.ready,
      AXI_00_RDATA_PARITY  => open,
      AXI_00_RDATA         => axi_slv_o(0).r.data,
      AXI_00_RID           => axi_slv_o(0).r.id,
      AXI_00_RLAST         => axi_slv_o(0).r.last,
      AXI_00_RRESP         => axi_slv_o(0).r.resp,
      AXI_00_RVALID        => axi_slv_o(0).r.valid,
      AXI_00_WREADY        => axi_slv_o(0).w.ready,
      AXI_00_BID           => axi_slv_o(0).b.id,
      AXI_00_BRESP         => axi_slv_o(0).b.resp,
      AXI_00_BVALID        => axi_slv_o(0).b.valid,

      AXI_04_ACLK          => clk_i,
      AXI_04_ARESET_N      => rstn_i,
      AXI_04_ARADDR        => axi_slv_i(1).ar.addr,
      AXI_04_ARBURST       => axi_slv_i(1).ar.burst,
      AXI_04_ARID          => axi_slv_i(1).ar.id,
      AXI_04_ARLEN         => axi_slv_i(1).ar.len,
      AXI_04_ARSIZE        => axi_slv_i(1).ar.size,
      AXI_04_ARVALID       => axi_slv_i(1).ar.valid,
      AXI_04_AWADDR        => axi_slv_i(1).aw.addr,
      AXI_04_AWBURST       => axi_slv_i(1).aw.burst,
      AXI_04_AWID          => axi_slv_i(1).aw.id,
      AXI_04_AWLEN         => axi_slv_i(1).aw.len,
      AXI_04_AWSIZE        => axi_slv_i(1).aw.size,
      AXI_04_AWVALID       => axi_slv_i(1).aw.valid,
      AXI_04_RREADY        => axi_slv_i(1).r.ready,
      AXI_04_BREADY        => axi_slv_i(1).b.ready,
      AXI_04_WDATA         => axi_slv_i(1).w.data,
      AXI_04_WLAST         => axi_slv_i(1).w.last,
      AXI_04_WSTRB         => axi_slv_i(1).w.strb,
      AXI_04_WDATA_PARITY  => (others => '1'),
      AXI_04_WVALID        => axi_slv_i(1).w.valid,
      AXI_04_ARREADY       => axi_slv_o(1).ar.ready,
      AXI_04_AWREADY       => axi_slv_o(1).aw.ready,
      AXI_04_RDATA_PARITY  => open,
      AXI_04_RDATA         => axi_slv_o(1).r.data,
      AXI_04_RID           => axi_slv_o(1).r.id,
      AXI_04_RLAST         => axi_slv_o(1).r.last,
      AXI_04_RRESP         => axi_slv_o(1).r.resp,
      AXI_04_RVALID        => axi_slv_o(1).r.valid,
      AXI_04_WREADY        => axi_slv_o(1).w.ready,
      AXI_04_BID           => axi_slv_o(1).b.id,
      AXI_04_BRESP         => axi_slv_o(1).b.resp,
      AXI_04_BVALID        => axi_slv_o(1).b.valid,

      AXI_08_ACLK          => clk_i,
      AXI_08_ARESET_N      => rstn_i,
      AXI_08_ARADDR        => axi_slv_i(2).ar.addr,
      AXI_08_ARBURST       => axi_slv_i(2).ar.burst,
      AXI_08_ARID          => axi_slv_i(2).ar.id,
      AXI_08_ARLEN         => axi_slv_i(2).ar.len,
      AXI_08_ARSIZE        => axi_slv_i(2).ar.size,
      AXI_08_ARVALID       => axi_slv_i(2).ar.valid,
      AXI_08_AWADDR        => axi_slv_i(2).aw.addr,
      AXI_08_AWBURST       => axi_slv_i(2).aw.burst,
      AXI_08_AWID          => axi_slv_i(2).aw.id,
      AXI_08_AWLEN         => axi_slv_i(2).aw.len,
      AXI_08_AWSIZE        => axi_slv_i(2).aw.size,
      AXI_08_AWVALID       => axi_slv_i(2).aw.valid,
      AXI_08_RREADY        => axi_slv_i(2).r.ready,
      AXI_08_BREADY        => axi_slv_i(2).b.ready,
      AXI_08_WDATA         => axi_slv_i(2).w.data,
      AXI_08_WLAST         => axi_slv_i(2).w.last,
      AXI_08_WSTRB         => axi_slv_i(2).w.strb,
      AXI_08_WDATA_PARITY  => (others => '1'),
      AXI_08_WVALID        => axi_slv_i(2).w.valid,
      AXI_08_ARREADY       => axi_slv_o(2).ar.ready,
      AXI_08_AWREADY       => axi_slv_o(2).aw.ready,
      AXI_08_RDATA_PARITY  => open,
      AXI_08_RDATA         => axi_slv_o(2).r.data,
      AXI_08_RID           => axi_slv_o(2).r.id,
      AXI_08_RLAST         => axi_slv_o(2).r.last,
      AXI_08_RRESP         => axi_slv_o(2).r.resp,
      AXI_08_RVALID        => axi_slv_o(2).r.valid,
      AXI_08_WREADY        => axi_slv_o(2).w.ready,
      AXI_08_BID           => axi_slv_o(2).b.id,
      AXI_08_BRESP         => axi_slv_o(2).b.resp,
      AXI_08_BVALID        => axi_slv_o(2).b.valid,

      AXI_12_ACLK          => clk_i,
      AXI_12_ARESET_N      => rstn_i,
      AXI_12_ARADDR        => axi_slv_i(3).ar.addr,
      AXI_12_ARBURST       => axi_slv_i(3).ar.burst,
      AXI_12_ARID          => axi_slv_i(3).ar.id,
      AXI_12_ARLEN         => axi_slv_i(3).ar.len,
      AXI_12_ARSIZE        => axi_slv_i(3).ar.size,
      AXI_12_ARVALID       => axi_slv_i(3).ar.valid,
      AXI_12_AWADDR        => axi_slv_i(3).aw.addr,
      AXI_12_AWBURST       => axi_slv_i(3).aw.burst,
      AXI_12_AWID          => axi_slv_i(3).aw.id,
      AXI_12_AWLEN         => axi_slv_i(3).aw.len,
      AXI_12_AWSIZE        => axi_slv_i(3).aw.size,
      AXI_12_AWVALID       => axi_slv_i(3).aw.valid,
      AXI_12_RREADY        => axi_slv_i(3).r.ready,
      AXI_12_BREADY        => axi_slv_i(3).b.ready,
      AXI_12_WDATA         => axi_slv_i(3).w.data,
      AXI_12_WLAST         => axi_slv_i(3).w.last,
      AXI_12_WSTRB         => axi_slv_i(3).w.strb,
      AXI_12_WDATA_PARITY  => (others => '1'),
      AXI_12_WVALID        => axi_slv_i(3).w.valid,
      AXI_12_ARREADY       => axi_slv_o(3).ar.ready,
      AXI_12_AWREADY       => axi_slv_o(3).aw.ready,
      AXI_12_RDATA_PARITY  => open,
      AXI_12_RDATA         => axi_slv_o(3).r.data,
      AXI_12_RID           => axi_slv_o(3).r.id,
      AXI_12_RLAST         => axi_slv_o(3).r.last,
      AXI_12_RRESP         => axi_slv_o(3).r.resp,
      AXI_12_RVALID        => axi_slv_o(3).r.valid,
      AXI_12_WREADY        => axi_slv_o(3).w.ready,
      AXI_12_BID           => axi_slv_o(3).b.id,
      AXI_12_BRESP         => axi_slv_o(3).b.resp,
      AXI_12_BVALID        => axi_slv_o(3).b.valid,

      AXI_16_ACLK          => clk_i,
      AXI_16_ARESET_N      => rstn_i,
      AXI_16_ARADDR        => axi_slv_i(4).ar.addr,
      AXI_16_ARBURST       => axi_slv_i(4).ar.burst,
      AXI_16_ARID          => axi_slv_i(4).ar.id,
      AXI_16_ARLEN         => axi_slv_i(4).ar.len,
      AXI_16_ARSIZE        => axi_slv_i(4).ar.size,
      AXI_16_ARVALID       => axi_slv_i(4).ar.valid,
      AXI_16_AWADDR        => axi_slv_i(4).aw.addr,
      AXI_16_AWBURST       => axi_slv_i(4).aw.burst,
      AXI_16_AWID          => axi_slv_i(4).aw.id,
      AXI_16_AWLEN         => axi_slv_i(4).aw.len,
      AXI_16_AWSIZE        => axi_slv_i(4).aw.size,
      AXI_16_AWVALID       => axi_slv_i(4).aw.valid,
      AXI_16_RREADY        => axi_slv_i(4).r.ready,
      AXI_16_BREADY        => axi_slv_i(4).b.ready,
      AXI_16_WDATA         => axi_slv_i(4).w.data,
      AXI_16_WLAST         => axi_slv_i(4).w.last,
      AXI_16_WSTRB         => axi_slv_i(4).w.strb,
      AXI_16_WDATA_PARITY  => (others => '1'),
      AXI_16_WVALID        => axi_slv_i(4).w.valid,
      AXI_16_ARREADY       => axi_slv_o(4).ar.ready,
      AXI_16_AWREADY       => axi_slv_o(4).aw.ready,
      AXI_16_RDATA_PARITY  => open,
      AXI_16_RDATA         => axi_slv_o(4).r.data,
      AXI_16_RID           => axi_slv_o(4).r.id,
      AXI_16_RLAST         => axi_slv_o(4).r.last,
      AXI_16_RRESP         => axi_slv_o(4).r.resp,
      AXI_16_RVALID        => axi_slv_o(4).r.valid,
      AXI_16_WREADY        => axi_slv_o(4).w.ready,
      AXI_16_BID           => axi_slv_o(4).b.id,
      AXI_16_BRESP         => axi_slv_o(4).b.resp,
      AXI_16_BVALID        => axi_slv_o(4).b.valid,

      AXI_20_ACLK          => clk_i,
      AXI_20_ARESET_N      => rstn_i,
      AXI_20_ARADDR        => axi_slv_i(5).ar.addr,
      AXI_20_ARBURST       => axi_slv_i(5).ar.burst,
      AXI_20_ARID          => axi_slv_i(5).ar.id,
      AXI_20_ARLEN         => axi_slv_i(5).ar.len,
      AXI_20_ARSIZE        => axi_slv_i(5).ar.size,
      AXI_20_ARVALID       => axi_slv_i(5).ar.valid,
      AXI_20_AWADDR        => axi_slv_i(5).aw.addr,
      AXI_20_AWBURST       => axi_slv_i(5).aw.burst,
      AXI_20_AWID          => axi_slv_i(5).aw.id,
      AXI_20_AWLEN         => axi_slv_i(5).aw.len,
      AXI_20_AWSIZE        => axi_slv_i(5).aw.size,
      AXI_20_AWVALID       => axi_slv_i(5).aw.valid,
      AXI_20_RREADY        => axi_slv_i(5).r.ready,
      AXI_20_BREADY        => axi_slv_i(5).b.ready,
      AXI_20_WDATA         => axi_slv_i(5).w.data,
      AXI_20_WLAST         => axi_slv_i(5).w.last,
      AXI_20_WSTRB         => axi_slv_i(5).w.strb,
      AXI_20_WDATA_PARITY  => (others => '1'),
      AXI_20_WVALID        => axi_slv_i(5).w.valid,
      AXI_20_ARREADY       => axi_slv_o(5).ar.ready,
      AXI_20_AWREADY       => axi_slv_o(5).aw.ready,
      AXI_20_RDATA_PARITY  => open,
      AXI_20_RDATA         => axi_slv_o(5).r.data,
      AXI_20_RID           => axi_slv_o(5).r.id,
      AXI_20_RLAST         => axi_slv_o(5).r.last,
      AXI_20_RRESP         => axi_slv_o(5).r.resp,
      AXI_20_RVALID        => axi_slv_o(5).r.valid,
      AXI_20_WREADY        => axi_slv_o(5).w.ready,
      AXI_20_BID           => axi_slv_o(5).b.id,
      AXI_20_BRESP         => axi_slv_o(5).b.resp,
      AXI_20_BVALID        => axi_slv_o(5).b.valid,

      AXI_24_ACLK          => clk_i,
      AXI_24_ARESET_N      => rstn_i,
      AXI_24_ARADDR        => axi_slv_i(6).ar.addr,
      AXI_24_ARBURST       => axi_slv_i(6).ar.burst,
      AXI_24_ARID          => axi_slv_i(6).ar.id,
      AXI_24_ARLEN         => axi_slv_i(6).ar.len,
      AXI_24_ARSIZE        => axi_slv_i(6).ar.size,
      AXI_24_ARVALID       => axi_slv_i(6).ar.valid,
      AXI_24_AWADDR        => axi_slv_i(6).aw.addr,
      AXI_24_AWBURST       => axi_slv_i(6).aw.burst,
      AXI_24_AWID          => axi_slv_i(6).aw.id,
      AXI_24_AWLEN         => axi_slv_i(6).aw.len,
      AXI_24_AWSIZE        => axi_slv_i(6).aw.size,
      AXI_24_AWVALID       => axi_slv_i(6).aw.valid,
      AXI_24_RREADY        => axi_slv_i(6).r.ready,
      AXI_24_BREADY        => axi_slv_i(6).b.ready,
      AXI_24_WDATA         => axi_slv_i(6).w.data,
      AXI_24_WLAST         => axi_slv_i(6).w.last,
      AXI_24_WSTRB         => axi_slv_i(6).w.strb,
      AXI_24_WDATA_PARITY  => (others => '1'),
      AXI_24_WVALID        => axi_slv_i(6).w.valid,
      AXI_24_ARREADY       => axi_slv_o(6).ar.ready,
      AXI_24_AWREADY       => axi_slv_o(6).aw.ready,
      AXI_24_RDATA_PARITY  => open,
      AXI_24_RDATA         => axi_slv_o(6).r.data,
      AXI_24_RID           => axi_slv_o(6).r.id,
      AXI_24_RLAST         => axi_slv_o(6).r.last,
      AXI_24_RRESP         => axi_slv_o(6).r.resp,
      AXI_24_RVALID        => axi_slv_o(6).r.valid,
      AXI_24_WREADY        => axi_slv_o(6).w.ready,
      AXI_24_BID           => axi_slv_o(6).b.id,
      AXI_24_BRESP         => axi_slv_o(6).b.resp,
      AXI_24_BVALID        => axi_slv_o(6).b.valid,

      AXI_28_ACLK          => clk_i,
      AXI_28_ARESET_N      => rstn_i,
      AXI_28_ARADDR        => axi_slv_i(7).ar.addr,
      AXI_28_ARBURST       => axi_slv_i(7).ar.burst,
      AXI_28_ARID          => axi_slv_i(7).ar.id,
      AXI_28_ARLEN         => axi_slv_i(7).ar.len,
      AXI_28_ARSIZE        => axi_slv_i(7).ar.size,
      AXI_28_ARVALID       => axi_slv_i(7).ar.valid,
      AXI_28_AWADDR        => axi_slv_i(7).aw.addr,
      AXI_28_AWBURST       => axi_slv_i(7).aw.burst,
      AXI_28_AWID          => axi_slv_i(7).aw.id,
      AXI_28_AWLEN         => axi_slv_i(7).aw.len,
      AXI_28_AWSIZE        => axi_slv_i(7).aw.size,
      AXI_28_AWVALID       => axi_slv_i(7).aw.valid,
      AXI_28_RREADY        => axi_slv_i(7).r.ready,
      AXI_28_BREADY        => axi_slv_i(7).b.ready,
      AXI_28_WDATA         => axi_slv_i(7).w.data,
      AXI_28_WLAST         => axi_slv_i(7).w.last,
      AXI_28_WSTRB         => axi_slv_i(7).w.strb,
      AXI_28_WDATA_PARITY  => (others => '1'),
      AXI_28_WVALID        => axi_slv_i(7).w.valid,
      AXI_28_ARREADY       => axi_slv_o(7).ar.ready,
      AXI_28_AWREADY       => axi_slv_o(7).aw.ready,
      AXI_28_RDATA_PARITY  => open,
      AXI_28_RDATA         => axi_slv_o(7).r.data,
      AXI_28_RID           => axi_slv_o(7).r.id,
      AXI_28_RLAST         => axi_slv_o(7).r.last,
      AXI_28_RRESP         => axi_slv_o(7).r.resp,
      AXI_28_RVALID        => axi_slv_o(7).r.valid,
      AXI_28_WREADY        => axi_slv_o(7).w.ready,
      AXI_28_BID           => axi_slv_o(7).b.id,
      AXI_28_BRESP         => axi_slv_o(7).b.resp,
      AXI_28_BVALID        => axi_slv_o(7).b.valid,

      APB_0_PCLK           => clk_i,
      APB_0_PRESET_N       => rstn_i,
      APB_1_PCLK           => clk_i,
      APB_1_PRESET_N       => rstn_i,
      apb_complete_0       => open,
      apb_complete_1       => open,
      DRAM_0_STAT_CATTRIP  => dram_stat_catrip_0,
      DRAM_0_STAT_TEMP     => open,
      DRAM_1_STAT_CATTRIP  => dram_stat_catrip_1,
      DRAM_1_STAT_TEMP     => open
      );

end;