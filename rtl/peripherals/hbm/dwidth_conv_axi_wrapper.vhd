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


-- This is a wrapper of the AXI DATAWIDTH CONVERTER IP from Xilinx.
-- It uses custom record types to bundle AXI signals.

library ieee;
use ieee.std_logic_1164.all;
use work.amba.all;
use work.hbm_pkg.all;

entity dwidth_conv_axi_wrapper is
  port (
    clk_i                    : in  std_ulogic;
    rstn_i                   : in  std_ulogic;
    axi_slv_i                : in  axix_mosi_type;
    axi_slv_o                : out axi_somi_type;
    axi_mst_i                : in  hbm_axi_somi_type;
    axi_mst_o                : out hbm_axi_mosi_type
    );
end dwidth_conv_axi_wrapper;

architecture rtl of dwidth_conv_axi_wrapper is


  component axi_dwidth_converter_ip
    port (
    s_axi_aclk : in   std_logic; 
    s_axi_aresetn : in std_logic;     
    s_axi_awid : in    std_logic_vector(9 downto 0); 
    s_axi_awaddr : in    std_logic_vector(31 downto 0);
    s_axi_awlen : in    std_logic_vector(3 downto 0); 
    s_axi_awsize : in    std_logic_vector(2 downto 0); 
    s_axi_awburst : in    std_logic_vector(1 downto 0); 
    s_axi_awlock : in    std_logic_vector(1 downto 0); 
    s_axi_awcache : in    std_logic_vector(3 downto 0); 
    s_axi_awprot : in    std_logic_vector(2 downto 0); 
    s_axi_awqos : in    std_logic_vector(3 downto 0); 
    s_axi_awvalid : in    std_logic; 
    s_axi_awready : out  std_logic;  
    s_axi_wdata : in    std_logic_vector(63 downto 0);
    s_axi_wstrb : in    std_logic_vector(7 downto 0); 
    s_axi_wlast : in     std_logic; 
    s_axi_wvalid : in    std_logic; 
    s_axi_wready : out   std_logic;  
    s_axi_bid : out    std_logic_vector(9 downto 0); 
    s_axi_bresp : out    std_logic_vector(1 downto 0); 
    s_axi_bvalid : out   std_logic;  
    s_axi_bready : in     std_logic; 
    s_axi_arid : in    std_logic_vector(9 downto 0); 
    s_axi_araddr : in    std_logic_vector(31 downto 0);
    s_axi_arlen : in    std_logic_vector(3 downto 0); 
    s_axi_arsize : in    std_logic_vector(2 downto 0); 
    s_axi_arburst : in    std_logic_vector(1 downto 0); 
    s_axi_arlock : in    std_logic_vector(1 downto 0); 
    s_axi_arcache : in    std_logic_vector(3 downto 0); 
    s_axi_arprot : in    std_logic_vector(2 downto 0); 
    s_axi_arqos : in    std_logic_vector(3 downto 0); 
    s_axi_arvalid : in     std_logic; 
    s_axi_arready : out   std_logic; 
    s_axi_rid : out    std_logic_vector(9 downto 0); 
    s_axi_rdata : out    std_logic_vector(63 downto 0);
    s_axi_rresp : out    std_logic_vector(1 downto 0); 
    s_axi_rlast : out    std_logic; 
    s_axi_rvalid : out   std_logic; 
    s_axi_rready : in    std_logic; 
    
    m_axi_awaddr : out    std_logic_vector(31 downto 0);
    m_axi_awlen : out    std_logic_vector(3 downto 0); 
    m_axi_awsize : out    std_logic_vector(2 downto 0); 
    m_axi_awburst : out    std_logic_vector(1 downto 0); 
    m_axi_awlock : out    std_logic_vector(1 downto 0); 
    m_axi_awcache : out    std_logic_vector(3 downto 0); 
    m_axi_awprot : out    std_logic_vector(2 downto 0); 
    m_axi_awqos : out    std_logic_vector(3 downto 0); 
    m_axi_awvalid : out   std_logic; 
    m_axi_awready : in    std_logic; 
    m_axi_wdata : out    std_logic_vector(255 downto 0);
    m_axi_wstrb : out    std_logic_vector(31 downto 0); 
    m_axi_wlast : out    std_logic; 
    m_axi_wvalid : out   std_logic; 
    m_axi_wready : in     std_logic; 
    m_axi_bresp : in    std_logic_vector(1 downto 0); 
    m_axi_bvalid : in     std_logic; 
    m_axi_bready : out   std_logic; 
    m_axi_araddr : out    std_logic_vector(31 downto 0);
    m_axi_arlen : out    std_logic_vector(3 downto 0); 
    m_axi_arsize : out    std_logic_vector(2 downto 0); 
    m_axi_arburst : out    std_logic_vector(1 downto 0); 
    m_axi_arlock : out    std_logic_vector(1 downto 0); 
    m_axi_arcache : out    std_logic_vector(3 downto 0); 
    m_axi_arprot : out    std_logic_vector(2 downto 0); 
    m_axi_arqos : out    std_logic_vector(3 downto 0); 
    m_axi_arvalid : out   std_logic;  
    m_axi_arready : in     std_logic; 
    m_axi_rdata : in    std_logic_vector(255 downto 0);
    m_axi_rresp : in    std_logic_vector(1 downto 0);  
    m_axi_rlast : in     std_logic; 
    m_axi_rvalid : in    std_logic; 
    m_axi_rready : out  std_logic  
  );
  end component axi_dwidth_converter_ip;

begin

  axi_dwidth_conv_i: axi_dwidth_converter_ip
    port map(
    s_axi_aclk     =>    clk_i,
    s_axi_aresetn     => rstn_i,
    
    s_axi_awid     =>    axi_slv_i.aw.id,
    s_axi_awaddr     =>  axi_slv_i.aw.addr(31 downto 0),
    s_axi_awlen     =>   axi_slv_i.aw.len(3 downto 0),
    s_axi_awsize     =>  axi_slv_i.aw.size,
    s_axi_awburst     => axi_slv_i.aw.burst,
    s_axi_awlock     =>  (others => '0'),
    s_axi_awcache     => axi_slv_i.aw.cache,
    s_axi_awprot     =>  axi_slv_i.aw.prot ,
    s_axi_awqos     =>   axi_slv_i.aw.qos  ,
    s_axi_awvalid     => axi_slv_i.aw.valid,
    s_axi_awready     => axi_slv_o.aw.ready,
    s_axi_wdata     =>   axi_slv_i.w.data ,
    s_axi_wstrb     =>   axi_slv_i.w.strb ,
    s_axi_wlast     =>   axi_slv_i.w.last ,
    s_axi_wvalid     =>  axi_slv_i.w.valid,
    s_axi_wready     =>  axi_slv_o.w.ready,
    s_axi_bid     =>     axi_slv_o.b.id   ,
    s_axi_bresp     =>   axi_slv_o.b.resp ,
    s_axi_bvalid     =>  axi_slv_o.b.valid,
    s_axi_bready     =>  axi_slv_i.b.ready,
    s_axi_arid     =>    axi_slv_i.ar.id   ,
    s_axi_araddr     =>  axi_slv_i.ar.addr(31 downto 0) ,
    s_axi_arlen     =>   axi_slv_i.ar.len(3 downto 0)  ,
    s_axi_arsize     =>  axi_slv_i.ar.size ,
    s_axi_arburst     => axi_slv_i.ar.burst,
    s_axi_arlock     =>  (others => '0'),
    s_axi_arcache     => axi_slv_i.ar.cache,
    s_axi_arprot     =>  axi_slv_i.ar.prot ,
    s_axi_arqos     =>   axi_slv_i.ar.qos  ,
    s_axi_arvalid     => axi_slv_i.ar.valid,
    s_axi_arready     => axi_slv_o.ar.ready,
    s_axi_rid     =>     axi_slv_o.r.id   ,
    s_axi_rdata     =>   axi_slv_o.r.data ,
    s_axi_rresp     =>   axi_slv_o.r.resp ,
    s_axi_rlast     =>   axi_slv_o.r.last ,
    s_axi_rvalid     =>  axi_slv_o.r.valid,
    s_axi_rready     =>  axi_slv_i.r.ready,
    
    m_axi_awaddr     =>  axi_mst_o.aw.addr(31 downto 0) ,
    m_axi_awlen      =>  axi_mst_o.aw.len(3 downto 0)  ,
    m_axi_awsize     =>  axi_mst_o.aw.size ,
    m_axi_awburst     => axi_mst_o.aw.burst,
    m_axi_awlock     =>  open,
    m_axi_awcache     => axi_mst_o.aw.cache,
    m_axi_awprot     =>  axi_mst_o.aw.prot ,
    m_axi_awqos     =>   axi_mst_o.aw.qos  ,
    m_axi_awvalid     => axi_mst_o.aw.valid,
    m_axi_awready     => axi_mst_i.aw.ready,
    m_axi_wdata     =>   axi_mst_o.w.data ,
    m_axi_wstrb     =>   axi_mst_o.w.strb ,
    m_axi_wlast     =>   axi_mst_o.w.last ,
    m_axi_wvalid     =>  axi_mst_o.w.valid,
    m_axi_wready     =>  axi_mst_i.w.ready,
    m_axi_bresp     =>   axi_mst_i.b.resp ,
    m_axi_bvalid     =>  axi_mst_i.b.valid,
    m_axi_bready     =>  axi_mst_o.b.ready,
    m_axi_araddr     =>  axi_mst_o.ar.addr(31 downto 0) ,
    m_axi_arlen     =>   axi_mst_o.ar.len(3 downto 0)  ,
    m_axi_arsize     =>  axi_mst_o.ar.size ,
    m_axi_arburst     => axi_mst_o.ar.burst,
    m_axi_arlock     =>  open,
    m_axi_arcache     => axi_mst_o.ar.cache,
    m_axi_arprot     =>  axi_mst_o.ar.prot ,
    m_axi_arqos     =>   axi_mst_o.ar.qos  ,
    m_axi_arvalid     => axi_mst_o.ar.valid,
    m_axi_arready     => axi_mst_i.ar.ready,
    m_axi_rdata     =>   axi_mst_i.r.data ,
    m_axi_rresp     =>   axi_mst_i.r.resp ,
    m_axi_rlast     =>   axi_mst_i.r.last ,
    m_axi_rvalid     =>  axi_mst_i.r.valid,
    m_axi_rready     =>  axi_mst_o.r.ready
  );

end;
