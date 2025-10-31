//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    write_logic.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This module has the task to compute the write address and signal if the fifo is full

`timescale 1ns / 1ps

module Write_Logic
    #(
    parameter   DEPTH   =   32,
    parameter   ADDR_WIDTH_OUT  =   5 
    ) 
    (
    clk,
    rst,
    
    valid_in,
    wraddr_out,
    full_out,
    
    wrptr_out,
    rdptr_in
    );
    
    localparam LOG2_DEPTH   =   $clog2(DEPTH);
    
    //I/O definitions
    input logic clk, rst;
    
    input logic valid_in;
    output logic[LOG2_DEPTH-1:0] wraddr_out;
    output logic full_out;
    
    output logic [LOG2_DEPTH:0] wrptr_out;
    input logic [ADDR_WIDTH_OUT:0] rdptr_in;
    
    
    //Additional logic
    logic[LOG2_DEPTH:0] grey_code, binary_code, grey_code_next, binary_code_next;
    logic [ADDR_WIDTH_OUT:0] rdptr_binary;
    logic [LOG2_DEPTH:0] rdptr_binary_converted;
    logic full;
    
    //If the data is valid and the fifo is not full, increase the write pointer
    assign binary_code_next = (rst == 1) ? '0 : binary_code + (valid_in && !full);
    //Convert the binary into a grey code
    assign grey_code_next = binary_code_next ^ (binary_code_next>>1);
    
    //Outputs assignment
    assign wrptr_out =  grey_code;
    assign wraddr_out = binary_code[LOG2_DEPTH-1:0];
    
    //Convert the rdptr to binary and adjust its size
    genvar i;
    generate
        for (i=0; i<ADDR_WIDTH_OUT+1; i++)
            assign rdptr_binary[i] = ^(rdptr_in >> i);
        
        if(ADDR_WIDTH_OUT > LOG2_DEPTH)
            assign rdptr_binary_converted = rdptr_binary>>(ADDR_WIDTH_OUT-LOG2_DEPTH);
        else if(ADDR_WIDTH_OUT == LOG2_DEPTH)    
            assign rdptr_binary_converted = rdptr_binary;
        else if(ADDR_WIDTH_OUT < LOG2_DEPTH)
            assign rdptr_binary_converted = rdptr_binary<<(LOG2_DEPTH-ADDR_WIDTH_OUT);       
    endgenerate
    
    //Full computation - it is full if all the bits of the write and read pointers are equal, except for the MSB
    assign full = ((binary_code[LOG2_DEPTH] !=rdptr_binary_converted[LOG2_DEPTH] ) &&
                    (binary_code[LOG2_DEPTH-1:0] ==rdptr_binary_converted[LOG2_DEPTH-1:0]));             
    assign full_out = full;
    
    //Sequential logic
    always_ff@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            binary_code <= '0;
            grey_code <= '0;
        end
        else
        begin
            binary_code <= binary_code_next;
            grey_code <= grey_code_next;
        end
    end
    
endmodule
