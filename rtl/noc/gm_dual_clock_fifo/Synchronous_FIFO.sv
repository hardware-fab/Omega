//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    Synchronous_FIFO.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This is just a wrapper for the BRAMs

`timescale 1ns / 1ps


module Synchronous_FIFO
    #(
    parameter DEPTH = 32,
    parameter BRAM_WIDTH    = 32,
    parameter WIDTH_IN = 32,
    parameter WIDTH_OUT = 128
    )
    (
        clk_wr,
        rst_wr,
        clk_rd,
        rst_rd,
        data_in,
        data_out,
        wraddr_in,
        rdaddr_in,
        wren_in,
    );
    
    localparam LOG2_DEPTH = $clog2(DEPTH);
    
    input logic clk_wr, rst_wr, clk_rd, rst_rd;
    input logic [WIDTH_IN-1:0] data_in;
    input logic[LOG2_DEPTH-1:0] wraddr_in, rdaddr_in;
    input logic wren_in;
    output logic [WIDTH_OUT-1:0] data_out;
    
    Parallel_BRAM_wrapper
    #(
        .BRAM_WIDTH(BRAM_WIDTH),
        .BRAM_DEPTH(512),
        .FIFO_WIDTH_IN(WIDTH_IN),
        .FIFO_WIDTH_OUT(WIDTH_OUT),
        .FIFO_DEPTH(DEPTH)
    ) BRAM_inst (
        .clk_wr(clk_wr),
        .clk_rd(clk_rd),
        .wren_in(wren_in),
        .wraddr_in(wraddr_in),
        .rdaddr_in(rdaddr_in),
        .data_in(data_in),
        .data_out(data_out)
    );
    
endmodule
