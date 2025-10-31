// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module dfadd_wrapper(rst, clk, acc_done, local_y, local_x, io_y, io_x, 
  pindex, paddr, pmask, pirq, \apbi[psel] , \apbi[penable] , \apbi[paddr] , \apbi[pwrite] , 
  \apbi[pwdata] , \apbi[pirq] , \apbi[testen] , \apbi[testrst] , \apbi[scanen] , 
  \apbi[testoen] , \apbi[testin] , \apbo[prdata] , \apbo[pirq] , \apbo[pconfig][0] , 
  \apbo[pconfig][1] , \apbo[pconfig][2] , \apbo[pindex] , \bank[0] , \bank[1] , \bank[2] , 
  \bank[3] , \bank[4] , \bank[5] , \bank[6] , \bank[7] , \bank[8] , \bank[9] , \bank[10] , 
  \bank[11] , \bank[12] , \bank[13] , \bank[14] , \bank[15] , \bank[16] , \bank[17] , \bank[18] , 
  \bank[19] , \bank[20] , \bank[21] , \bank[22] , \bank[23] , \bank[24] , \bank[25] , \bank[26] , 
  \bank[27] , \bank[28] , \bank[29] , \bank[30] , \bank[31] , \bank[32] , \bank[33] , \bank[34] , 
  \bank[35] , \bank[36] , \bank[37] , \bank[38] , \bank[39] , \bank[40] , \bank[41] , \bank[42] , 
  \bank[43] , \bank[44] , \bank[45] , \bank[46] , \bank[47] , \bank[48] , \bank[49] , \bank[50] , 
  \bank[51] , \bank[52] , \bank[53] , \bank[54] , \bank[55] , \bank[56] , \bank[57] , \bank[58] , 
  \bank[59] , \bank[60] , \bank[61] , \bank[62] , \bank[63] , conf_done, flush, acc_flush_done, 
  \mon_dvfs_in[clk] , \mon_dvfs_in[vf] , \mon_dvfs_in[acc_idle] , \mon_dvfs_in[traffic] , 
  \mon_dvfs_in[burst] , \mon_dvfs_in[transient] , \mon_dvfs_feedthru[clk] , 
  \mon_dvfs_feedthru[vf] , \mon_dvfs_feedthru[acc_idle] , \mon_dvfs_feedthru[traffic] , 
  \mon_dvfs_feedthru[burst] , \mon_dvfs_feedthru[transient] , coherent_dma_rcv_rdreq, 
  coherent_dma_rcv_data_out, coherent_dma_rcv_empty, coherent_dma_snd_wrreq, 
  coherent_dma_snd_data_in, coherent_dma_snd_full, dma_read, dma_write, dma_length, 
  dma_address, dma_ready, dma_rcv_rdreq_int, dma_rcv_data_out_int, dma_rcv_empty_int, 
  dma_snd_wrreq_int, dma_snd_data_in_int, dma_snd_full_int, interrupt_wrreq, 
  interrupt_data_in, interrupt_full, mon_acc_roundtrip_time);
  input rst;
  input clk /* synthesis syn_isclock = 1 */;
  output acc_done;
  input [2:0]local_y;
  input [2:0]local_x;
  input [2:0]io_y;
  input [2:0]io_x;
  input [31:0]pindex;
  input [31:0]paddr;
  input [31:0]pmask;
  input [31:0]pirq;
  input [0:127]\apbi[psel] ;
  input \apbi[penable] ;
  input [31:0]\apbi[paddr] ;
  input \apbi[pwrite] ;
  input [31:0]\apbi[pwdata] ;
  input [31:0]\apbi[pirq] ;
  input \apbi[testen] ;
  input \apbi[testrst] ;
  input \apbi[scanen] ;
  input \apbi[testoen] ;
  input [3:0]\apbi[testin] ;
  output [31:0]\apbo[prdata] ;
  output [31:0]\apbo[pirq] ;
  output [31:0]\apbo[pconfig][0] ;
  output [31:0]\apbo[pconfig][1] ;
  output [31:0]\apbo[pconfig][2] ;
  output [6:0]\apbo[pindex] ;
  output [31:0]\bank[0] ;
  output [31:0]\bank[1] ;
  output [31:0]\bank[2] ;
  output [31:0]\bank[3] ;
  output [31:0]\bank[4] ;
  output [31:0]\bank[5] ;
  output [31:0]\bank[6] ;
  output [31:0]\bank[7] ;
  output [31:0]\bank[8] ;
  output [31:0]\bank[9] ;
  output [31:0]\bank[10] ;
  output [31:0]\bank[11] ;
  output [31:0]\bank[12] ;
  output [31:0]\bank[13] ;
  output [31:0]\bank[14] ;
  output [31:0]\bank[15] ;
  output [31:0]\bank[16] ;
  output [31:0]\bank[17] ;
  output [31:0]\bank[18] ;
  output [31:0]\bank[19] ;
  output [31:0]\bank[20] ;
  output [31:0]\bank[21] ;
  output [31:0]\bank[22] ;
  output [31:0]\bank[23] ;
  output [31:0]\bank[24] ;
  output [31:0]\bank[25] ;
  output [31:0]\bank[26] ;
  output [31:0]\bank[27] ;
  output [31:0]\bank[28] ;
  output [31:0]\bank[29] ;
  output [31:0]\bank[30] ;
  output [31:0]\bank[31] ;
  output [31:0]\bank[32] ;
  output [31:0]\bank[33] ;
  output [31:0]\bank[34] ;
  output [31:0]\bank[35] ;
  output [31:0]\bank[36] ;
  output [31:0]\bank[37] ;
  output [31:0]\bank[38] ;
  output [31:0]\bank[39] ;
  output [31:0]\bank[40] ;
  output [31:0]\bank[41] ;
  output [31:0]\bank[42] ;
  output [31:0]\bank[43] ;
  output [31:0]\bank[44] ;
  output [31:0]\bank[45] ;
  output [31:0]\bank[46] ;
  output [31:0]\bank[47] ;
  output [31:0]\bank[48] ;
  output [31:0]\bank[49] ;
  output [31:0]\bank[50] ;
  output [31:0]\bank[51] ;
  output [31:0]\bank[52] ;
  output [31:0]\bank[53] ;
  output [31:0]\bank[54] ;
  output [31:0]\bank[55] ;
  output [31:0]\bank[56] ;
  output [31:0]\bank[57] ;
  output [31:0]\bank[58] ;
  output [31:0]\bank[59] ;
  output [31:0]\bank[60] ;
  output [31:0]\bank[61] ;
  output [31:0]\bank[62] ;
  output [31:0]\bank[63] ;
  output conf_done;
  output flush;
  input acc_flush_done;
  input \mon_dvfs_in[clk] ;
  input [3:0]\mon_dvfs_in[vf] ;
  input \mon_dvfs_in[acc_idle] ;
  input \mon_dvfs_in[traffic] ;
  input \mon_dvfs_in[burst] ;
  input \mon_dvfs_in[transient] ;
  output \mon_dvfs_feedthru[clk]  /* synthesis syn_isclock = 1 */;
  output [3:0]\mon_dvfs_feedthru[vf] ;
  output \mon_dvfs_feedthru[acc_idle] ;
  output \mon_dvfs_feedthru[traffic] ;
  output \mon_dvfs_feedthru[burst] ;
  output \mon_dvfs_feedthru[transient] ;
  output coherent_dma_rcv_rdreq;
  input [65:0]coherent_dma_rcv_data_out;
  input coherent_dma_rcv_empty;
  output coherent_dma_snd_wrreq;
  output [65:0]coherent_dma_snd_data_in;
  input coherent_dma_snd_full;
  output dma_read;
  output dma_write;
  output [31:0]dma_length;
  output [31:0]dma_address;
  input dma_ready;
  output dma_rcv_rdreq_int;
  input [65:0]dma_rcv_data_out_int;
  input dma_rcv_empty_int;
  output dma_snd_wrreq_int;
  output [65:0]dma_snd_data_in_int;
  input dma_snd_full_int;
  output interrupt_wrreq;
  output [33:0]interrupt_data_in;
  input interrupt_full;
  output [15:0]mon_acc_roundtrip_time;
endmodule
