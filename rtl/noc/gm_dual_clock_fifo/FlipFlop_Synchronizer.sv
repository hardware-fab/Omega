//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    FlipFlop_Synchronizer.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This module is a simple flip-flop synchronizer with a configurable width and a configurable number of stages.
//The registers are used to increase the Mean Time Between Failures (MTBF): more registers are added in sequence, and less likely it is that a metastable signal
//can propagate to the design.

//For normal designs, 2 flip-flops are enough. For high speed ones, use three.

`timescale 1ns / 1ps

module FlipFlop_Synchronizer
    #(
    parameter STAGES    =   2,
    parameter WIDTH     =   5
    )
    (
    clk,
    rst,
    data_in,
    data_out
    );
    
    input logic clk, rst;
    input logic[WIDTH-1:0] data_in;
    output logic[WIDTH-1:0] data_out;
    
    //Specify that the synchronizing registers are asynchronous (to avoid timing issues)
    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0][WIDTH-1:0] sync_stages;
    
    always_ff@(posedge clk)
    begin
        //On reset, the registers are emptied
        if(rst)
        begin
            sync_stages <= '0;
            data_out <=  '0;
        end
        else
        //The module works exactly as a shift register
        begin
            sync_stages[0] <= data_in;
            for(int i=0; i<STAGES-1; i++)
                sync_stages[i+1] <= sync_stages[i];
            data_out <= sync_stages[STAGES-1];
        end
    end
endmodule
