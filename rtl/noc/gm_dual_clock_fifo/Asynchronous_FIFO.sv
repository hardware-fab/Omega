//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    Asynchronous_FIFO.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This is the main module. Basically it connects all the other modules, with a little amount of logic only for the last signal propagation.
`timescale 1ns / 1ps

module Asynchronous_FIFO
    #(
    parameter  WIDTH_IN = 8,
    parameter  WIDTH_OUT = 8,
    parameter  BRAM_WIDTH = 32,
    parameter  DEPTH = 16,
    parameter  N_OF_SYNC_STGS = 2
    )
    (
    clk_wr,
    rst_wr,
    data_wr,
    valid_wr,
    ready_wr,
    
    clk_rd,
    rst_rd,
    data_rd,
    valid_rd,
    ready_rd

    );
    
    localparam LOG2_DEPTH = $clog2(DEPTH);
    
    //Conventionally, the minimum data width is the one of the BRAM
    localparam WIDTH_MIN  = BRAM_WIDTH;
    //Number of words of which the input and the output are composed
    localparam WORDS_OUT  = WIDTH_OUT/WIDTH_MIN;
    localparam WORDS_IN  = WIDTH_IN/WIDTH_MIN;
    //Depth of the fifo w.r.t. the input and the output data width
    localparam DEPTH_IN = DEPTH/WORDS_IN;
    localparam DEPTH_OUT = DEPTH/WORDS_OUT;
    //Size of the input and output addresses
    localparam ADDR_WIDTH_IN = $clog2(DEPTH_IN);
    localparam ADDR_WIDTH_OUT = $clog2(DEPTH_OUT);
    
    //I/O definitions
    
    input logic clk_wr, rst_wr;
    input logic [WIDTH_IN-1:0] data_wr;
    input logic valid_wr;
    output logic ready_wr;
    
    input logic clk_rd, rst_rd;
    output logic [WIDTH_OUT-1:0] data_rd;
    output logic valid_rd;
    input logic ready_rd;
    
    //Wires
    logic[ADDR_WIDTH_IN-1:0] wraddr;
    logic[ADDR_WIDTH_OUT-1:0] rdaddr;
    logic[LOG2_DEPTH-1:0] wraddr_fifo, rdaddr_fifo;
    logic[ADDR_WIDTH_IN:0] wrptr_src, wrptr_dst;
    logic[ADDR_WIDTH_OUT:0] rdptr_src, rdptr_dst;
    logic full, empty;
    logic wren;
    
    //Ready, valid and wren assignment
    assign ready_wr = ~full;
    assign valid_rd = ~empty;
    assign wren = valid_wr & ready_wr;
    
    //Read and write addresses are shifted, since each input or output data may correspond to more words
    assign wraddr_fifo = wraddr << (LOG2_DEPTH-ADDR_WIDTH_IN);
    assign rdaddr_fifo = rdaddr << (LOG2_DEPTH-ADDR_WIDTH_OUT);
    
    //Modules instantiation
    
    Synchronous_FIFO #(
    .DEPTH(DEPTH),
    .BRAM_WIDTH(BRAM_WIDTH),
    .WIDTH_IN(WIDTH_IN),
    .WIDTH_OUT(WIDTH_OUT)
    ) sync_FIFO_inst (
        .clk_wr(clk_wr),
        .rst_wr(rst_wr),
        .clk_rd(clk_rd),
        .rst_rd(rst_rd),
        .data_in(data_wr),
        .data_out(data_rd),
        .wraddr_in(wraddr_fifo),
        .rdaddr_in(rdaddr_fifo),
        .wren_in(wren)
    );
    
    Write_Logic#(
        .DEPTH(DEPTH_IN),
        .ADDR_WIDTH_OUT(ADDR_WIDTH_OUT)
    ) write_logic_inst (
    .clk(clk_wr),
    .rst(rst_wr),
    .valid_in(valid_wr),
    .wraddr_out(wraddr),
    .full_out(full),
    .wrptr_out(wrptr_src),
    .rdptr_in(rdptr_dst)
    );
    
    Read_Logic#(
        .DEPTH(DEPTH_OUT),
        .ADDR_WIDTH_IN(ADDR_WIDTH_IN)
    ) read_logic_inst (
    .clk(clk_rd),
    .rst(rst_rd),
    .ready_in(ready_rd),
    .rdaddr_out(rdaddr),
    .empty_out(empty),
    .rdptr_out(rdptr_src),
    .wrptr_in(wrptr_dst)
    );
    
    FlipFlop_Synchronizer #(
        .STAGES(N_OF_SYNC_STGS),
        .WIDTH(ADDR_WIDTH_IN+1)
    ) wr2rd_sync_inst (
    .clk(clk_rd),
    .rst(rst_rd),
    .data_in(wrptr_src),
    .data_out(wrptr_dst)
    );
    
    FlipFlop_Synchronizer #(
        .STAGES(N_OF_SYNC_STGS),
        .WIDTH(ADDR_WIDTH_OUT+1)
    ) rd2wr_sync_inst (
    .clk(clk_wr),
    .rst(rst_wr),
    .data_in(rdptr_src),
    .data_out(rdptr_dst)
    );
    
    
endmodule
