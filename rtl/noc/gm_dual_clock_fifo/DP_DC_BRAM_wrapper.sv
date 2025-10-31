//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    DP_DC_BRAM_wrapper.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This module has the task to instantiate and coordinate a certain number of BRAM in parallel, in order to reach the desired bandwidth.
//Note that the input and output data width can be different.

`timescale 1ns / 1ps

module Parallel_BRAM_wrapper
    #(
    parameter BRAM_WIDTH        =   32,     //32 or 64 bits
    parameter BRAM_DEPTH        =   512,    //Fixed to 512
    parameter FIFO_WIDTH_IN     =   32,     //Should be a power of two >= BRAM_WIDTH
    parameter FIFO_WIDTH_OUT    =   128,    //Should be a power of two >= BRAM_WIDTH
    parameter FIFO_DEPTH        =   32      //Should be a power of two <= BRAM_DEPTH
    )
    (
    clk_wr,
    clk_rd,
    wren_in,
    wraddr_in,
    rdaddr_in,
    data_in,
    data_out);
    
    //Addresses dimensions
    localparam BRAM_ADDR_WIDTH = $clog2(BRAM_DEPTH);
    localparam FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    //The number of BRAM depends on the max data width between input and output
    localparam WIDTH_MAX    =   (FIFO_WIDTH_IN > FIFO_WIDTH_OUT) ? FIFO_WIDTH_IN : FIFO_WIDTH_OUT;
    localparam NUM_BRAM     =   (WIDTH_MAX/BRAM_WIDTH);
    localparam LOG2_NUM_BRAM    =   $clog2(NUM_BRAM);
    
    //The ratios between the I/O and the BRAM data width
    localparam RATIO_IN     =   FIFO_WIDTH_IN/BRAM_WIDTH;
    localparam RATIO_OUT    =   FIFO_WIDTH_OUT/BRAM_WIDTH;
    
    //I/O definitions
    input clk_wr,clk_rd,wren_in;
    input [FIFO_ADDR_WIDTH-1:0] wraddr_in,rdaddr_in;
    input [FIFO_WIDTH_IN-1:0] data_in;
    output logic [FIFO_WIDTH_OUT-1:0] data_out;
    
    //Single BRAMs I/O
    logic clka,clkb,ena,enb;
    logic [BRAM_ADDR_WIDTH-1:0] bram_wraddr, bram_rdaddr;
    logic [NUM_BRAM-1:0][BRAM_WIDTH-1:0]    bram_data_in, bram_data_out;
    logic [NUM_BRAM-1:0] bram_wren;
    
    //Additional logic
    logic [LOG2_NUM_BRAM-1:0] rdaddr_ff;        //Register containing the old read address
    logic [RATIO_IN-1:0][BRAM_WIDTH-1:0] data_in_sec;       //Input data divided in single words
    logic [RATIO_OUT-1:0][BRAM_WIDTH-1:0] data_out_sec;     //Output data divided in single words
    logic [LOG2_NUM_BRAM:0] wr_index, rd_index;     //Indexes to choose the BRAM, a bit larger than needed to avoid negative dimensions
    
    //Just a name change
    assign clka = clk_wr;
    assign clkb = clk_rd;
    
    genvar i, j;
    generate
    //Input and output data divided in sections, to make code more readable
    for(i = 0; i<RATIO_IN; i++)
        assign data_in_sec[i] = data_in[BRAM_WIDTH*(i+1)-1:BRAM_WIDTH*i];
    
    for(i = 0; i<RATIO_OUT; i++)
        assign data_out[BRAM_WIDTH*(i+1)-1:BRAM_WIDTH*i] = data_out_sec[i];   
    endgenerate
    
    generate
        //Connect the input of the fifo with the inputs of the BRAMS
        for(i = 0; i<RATIO_IN; i++)
        begin
            for(j = 0; j<NUM_BRAM; j++)
            begin
                if(i == j%RATIO_IN)
                    assign bram_data_in[j] = data_in_sec[i];
            end
        end
    endgenerate
    
    //BRAM address computation - the first bits of the FIFO address are ignored here
    //since they are used to choose the BRAM
    generate
        assign bram_wraddr[BRAM_ADDR_WIDTH-1:FIFO_ADDR_WIDTH-LOG2_NUM_BRAM] = '0;
        assign bram_wraddr[FIFO_ADDR_WIDTH-LOG2_NUM_BRAM-1:0] = wraddr_in>>LOG2_NUM_BRAM;
        
        assign bram_rdaddr[BRAM_ADDR_WIDTH-1:FIFO_ADDR_WIDTH-LOG2_NUM_BRAM] = '0;
        assign bram_rdaddr[FIFO_ADDR_WIDTH-LOG2_NUM_BRAM-1:0] = rdaddr_in>>LOG2_NUM_BRAM;
    endgenerate
    
    //Enables are always active
    assign ena = 1;
    assign enb = 1;
    
    //The first bits of the addresses are used to compute the BRAM where to store/read the data
    //Note that for the read, the old address must be used
    generate
        if(LOG2_NUM_BRAM > 0)
        begin
            assign wr_index[LOG2_NUM_BRAM] = 0;
            assign rd_index[LOG2_NUM_BRAM] = 0;
            assign wr_index[LOG2_NUM_BRAM-1:0] = wraddr_in[LOG2_NUM_BRAM-1:0];
            assign rd_index[LOG2_NUM_BRAM-1:0] = rdaddr_ff;
        end
        else
        begin
            assign wr_index = '0;
            assign rd_index = '0;
        end
    endgenerate
    
    //Combinatorial logic
    always_comb
    begin
        //Write enable computation, based on the write index
        //(Note that the data connection between input and BRAMs is fixed!)
        bram_wren = '0;
        for(int count = 0; count<RATIO_IN; count++)
            bram_wren[wr_index+count] = wren_in;
        //Data out computation, based on the read index     
        for(int count = 0; count<RATIO_OUT; count++)
            data_out_sec[count] = bram_data_out[rd_index+count];     
    end
    
    //Sequential logic - only one register
    always_ff@(posedge clk_rd)
    begin
        rdaddr_ff <= rdaddr_in[LOG2_NUM_BRAM-1:0];
    end
    
    //Generation of the BRAMs
    generate
        for(i = 0; i<NUM_BRAM; i++)
        begin
            dual_port_dual_clk_BRAM #(
                .BRAM_WIDTH(BRAM_WIDTH),
                .BRAM_DEPTH(BRAM_DEPTH)
            ) DP_DC_BRAM_inst (
                .clka(clka),
                .clkb(clkb),
                .ena(ena),
                .enb(enb),
                .wea(bram_wren[i]),
                .addra(bram_wraddr),
                .addrb(bram_rdaddr),
                .dia(bram_data_in[i]),
                .dob(bram_data_out[i])
            );
        end     
    endgenerate
endmodule
