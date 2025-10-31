//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    Read_Logic.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This module is used to compute the empty signal, the read address, and also to set the last when needed
`timescale 1ns / 1ps

module Read_Logic
    #(
    parameter   DEPTH   =   16,
    parameter   ADDR_WIDTH_IN   =   4
    ) 
    (
    clk,
    rst,
    
    ready_in,
    rdaddr_out,
    empty_out,
    
    rdptr_out,
    wrptr_in
    );
    
    localparam LOG2_DEPTH   =   $clog2(DEPTH);
    
    //I/O definition
    input logic clk, rst;
    
    input logic ready_in;
    output logic[LOG2_DEPTH-1:0] rdaddr_out;
    output logic empty_out;
    
    output logic [LOG2_DEPTH:0] rdptr_out;
    input logic [ADDR_WIDTH_IN:0] wrptr_in;
    
    //Additional logic
    
    //Grey and binary codes to keep track of the read pointer
    logic[LOG2_DEPTH:0] grey_code, binary_code, grey_code_next, binary_code_next;
    
    //Internal empty signal
    logic empty;
    
    //Write pointer coming from the write logic module and synchronized
    logic [ADDR_WIDTH_IN:0] wrptr_binary;
    logic [LOG2_DEPTH:0] wrptr_binary_converted;
    
    //Binary code is increased if a valid data is read
    assign binary_code_next = (rst == 1) ? '0 : binary_code + (ready_in & !empty);
    //Then it is converted into grey code and sent to the write logic
    assign grey_code_next = binary_code_next ^ (binary_code_next>>1);
    assign rdptr_out =  grey_code;
    
    //Read address is taken directly from the binary code
    //Note that this is the next one, to take into account the 1-clk delay of the BRAM
    assign rdaddr_out = binary_code_next[LOG2_DEPTH-1:0];
    
    //Convert the wrptr to binary and adjust its size
    genvar i;
    generate
        for (i=0; i<ADDR_WIDTH_IN+1; i++)
            assign wrptr_binary[i] = ^(wrptr_in >> i);
        
        if(ADDR_WIDTH_IN > LOG2_DEPTH)
            assign wrptr_binary_converted = wrptr_binary>>(ADDR_WIDTH_IN-LOG2_DEPTH);
        else if(ADDR_WIDTH_IN == LOG2_DEPTH)    
            assign wrptr_binary_converted = wrptr_binary;
        else if(ADDR_WIDTH_IN < LOG2_DEPTH)
            assign wrptr_binary_converted = wrptr_binary<<(LOG2_DEPTH-ADDR_WIDTH_IN);       
    endgenerate
    
    //Empty computation - if write and read pointers are equal (considering also the extra bit), then the fifo is empty
    assign empty = (binary_code == wrptr_binary_converted || rst == 1) ? 1 : 0;
    assign empty_out = empty;
     
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
            //Update of the binary and grey registers
            binary_code <= binary_code_next;
            grey_code <= grey_code_next;
            
        end
        
    end
    
endmodule
