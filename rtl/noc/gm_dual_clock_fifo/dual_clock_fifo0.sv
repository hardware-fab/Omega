//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    dual_clock_fifo0.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This design contains a dual clock and dual data width fifo. Its task is to accelerate the data transmission to designs that suffers from a low clock frequency.
//Basically, it works like a funnel: where the clock is low (accelerator part), the data width is large, and where the clock is high (DDR/CPU part) the data width is
//limited (to 32/64 bit channels). It is based on the dual-clock BRAMs featured by xilinx devices, and it has an axi-stream interface (note that the keep information
//is not used).

//This design is based on the one described in the article "Simulation and Synthesis Techniques for Asynchronous FIFO Design" by Clifford Cummings: it has been modified
//to use BRAMs instead of simple registers (since xilinx's registers can't be used with two different clocks!), to have two different datawidths for the input and
//the output, and to satisfy the axi-stream protocol (in particular for the "last" signal).


//This file contains a simple wrapper, used to expose the axi-stream protocol to the rest of the block design.


//EDIT: this is a version of the fifo specifically designed for the ESP system. The changes are minimal (removed the last signal and changed the signals' names).
		
`timescale 1ns / 1ps

module dual_clock_fifo0#(
    parameter  depth = 5,
    parameter  width = 32
    )
    (
    input clk_wr,
    input clk_rd,
    input rst_wr, //They call it rst, but it's actually active low
    input rst_rd, //They call it rst, but it's actually active low
    input rdreq,
    input wrreq,
    input [width-1:0] data_in,
    output empty,
    output full,
    output [width-1:0] data_out
    );
    
    localparam BRAM_WIDTH = 32;
    localparam NUMBER_OF_SYNCHRONIZATION_STAGES = 2;
    
    localparam INTERNAL_WIDTH = 32*2**((width-1)/32);

    logic rst_wr_active_high;
    logic rst_rd_active_high;
    logic ready_in;
    logic valid_out;

    logic [INTERNAL_WIDTH-1:0] data_in_int, data_out_int;

    //Signals to avoid the not inside components' instantiations
    assign rst_wr_active_high = ~rst_wr;
    assign rst_rd_active_high = ~rst_rd;
    assign full = ~ready_in;
    assign empty = ~valid_out;

    //Adjust port width, since they are not always multiples of 32
    assign data_in_int[width-1:0] = data_in;
    assign data_in_int[INTERNAL_WIDTH-1:width] = '0;
    assign data_out = data_out_int[width-1:0];

     Asynchronous_FIFO #(
    .WIDTH_IN(INTERNAL_WIDTH),
    .WIDTH_OUT(INTERNAL_WIDTH),
    .BRAM_WIDTH(BRAM_WIDTH),
    .DEPTH(depth),
    .N_OF_SYNC_STGS(NUMBER_OF_SYNCHRONIZATION_STAGES)
    ) asynchronous_FIFO_inst (
    .clk_wr(clk_wr),
    .rst_wr(rst_wr_active_high),
    .data_wr(data_in_int),
    .valid_wr(wrreq),
    .ready_wr(ready_in),
    
    .clk_rd(clk_rd),
    .rst_rd(rst_rd_active_high),
    .data_rd(data_out_int),
    .valid_rd(valid_out),
    .ready_rd(rdreq)
    );
    
endmodule
