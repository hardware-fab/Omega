// ============================================================================
// Project:   AES for ESP
// Authors:   Gabriele Montanaro, Andrea Galimberti, Davide Zoni
//
// Description:
//
// AES cipher written in SystemVerilog.
//
// Copyright (c) Politecnico di Milano
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
// ============================================================================
//
// Module: aes_axis_wrapper
// Description: an axi-stream wrapper for the AES design
//
// ============================================================================


//SUFFIXES:
//i: input
//o: output
//n: input of a register (assigned in combinatorial processes, read in sequential processes)
//r: output of a register (read in combinatorial processes, assigned in sequential processes)
//w: wire (used only in combinatorial processes)
//t: type
//cs: current state (read in combinatorial processes, assigned in sequential processes)
//ns: next state (assigned in combinatorial processes, read in sequential processes)
//S: state


`timescale 1ns / 1ps

module aes_axis_wrapper
  (
    input  logic          clk_i,
    input  logic          rst_i,
    //Input data channel - reading from memory
    input  logic[64-1:0]  rd_block_data_i,
    input  logic          rd_block_valid_i,
    output logic          rd_block_ready_o,
    //Input key channel - reading from memory
    input  logic[64-1:0]  rd_key_data_i,
    input  logic          rd_key_valid_i,
    output logic          rd_key_ready_o,
    //Output data channel - writing to memory
    output logic [64-1:0] wr_data_o,
    output logic          wr_valid_o,
    input  logic          wr_ready_i
  );

  localparam                      AES_KEY_SIZE      =   256;
  localparam                      AES_BLOCK_SIZE    =   128;

  localparam                      WORDSIZE          =   64;

  localparam                      AES_KEY_WORDS     =   (AES_KEY_SIZE/WORDSIZE);
  localparam                      AES_BLOCK_WORDS   =   (AES_BLOCK_SIZE/WORDSIZE);

//////////////////////////////////////////////////////////////////////////////
//    internal wires                                //
//////////////////////////////////////////////////////////////////////////////

  logic                              aes_init_w;
  logic                              aes_next_w;
  logic                              aes_ready_w;
  logic                              aes_valid_w;

  logic [AES_KEY_SIZE-1:0]           aes_key_r, aes_key_n;
  logic [AES_BLOCK_SIZE-1:0]         aes_block_r, aes_block_n;
  logic [AES_BLOCK_SIZE-1:0]         aes_result_r, aes_result_n, aes_result_w;

  logic [$clog2(AES_KEY_WORDS)-1:0]  cnt_n, cnt_r;

  typedef enum logic  [2:0]
  {
    IDLE_S            =  'd0,
    READ_KEY_S        =  'd1,
    WRITE_KEY_S       =  'd2,
    READ_BLOCK_S      =  'd3,
    WRITE_BLOCK_S     =  'd4,
    READ_RESULT_S     =  'd5,
    WRITE_RESULT_S    =  'd6
  } state_t;

  state_t fsm_cs, fsm_ns;

//////////////////////////////////////////////////////////////////////////////
//    internal submodules                           //
//////////////////////////////////////////////////////////////////////////////

  aes_core aes_inst (
    .clk           (clk_i),
    .reset_n       (~rst_i),

    .init          (aes_init_w),
    .next          (aes_next_w),
    .ready         (aes_ready_w),

    .key           (aes_key_r),

    .block         (aes_block_r),
    .result        (aes_result_w),
    .result_valid  (aes_valid_w)
    );

//////////////////////////////////////////////////////////////////////////////
//      wire assignments                                       //
//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
//      sequential logic                                       //
//////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i)
  begin
    if (rst_i)
    begin
      fsm_cs            <=   IDLE_S  ;
      cnt_r             <=   '0;
      aes_key_r         <=   '0;
      aes_block_r       <=   '0;
      aes_result_r      <=   '0;
    end
    else
    begin
      fsm_cs            <=   fsm_ns;
      cnt_r             <=   cnt_n;
      aes_key_r         <=   aes_key_n;
      aes_block_r       <=   aes_block_n;
      aes_result_r      <=   aes_result_n;
    end
  end

//////////////////////////////////////////////////////////////////////////////
//      combinational logic                                       //
//////////////////////////////////////////////////////////////////////////////

  always_comb
  begin

    //State machine
    fsm_ns             =   fsm_cs;

    //Registers
    cnt_n              =   cnt_r;
    aes_key_n          =   aes_key_r;
    aes_block_n        =   aes_block_r;
    aes_result_n       =   aes_result_r;

    //Wires
    aes_init_w         =   '0;
    aes_next_w         =   '0;

    //Outputs
    rd_key_ready_o     =   '0;
    rd_block_ready_o   =   '0;
    wr_data_o          =   '0;
    wr_valid_o         =   '0;

    case (fsm_cs)
      //IDLE: AES is waiting to start operation
      IDLE_S:
      begin
        // Valid data arrives
        rd_block_ready_o = 1'b1;
        rd_key_ready_o   = 1'b1;
        cnt_n            = '0;
        if (rd_key_valid_i)
        begin
          fsm_ns         =   READ_KEY_S;
          cnt_n = cnt_r + 1;
          for(int i=0; i<WORDSIZE; i++)
            aes_key_n[WORDSIZE*cnt_r+i] = rd_key_data_i[i];
        end
        else if (rd_block_valid_i)
        begin
          fsm_ns         =   READ_BLOCK_S;
          cnt_n = cnt_r + 1;
          for(int i=0; i<WORDSIZE; i++)
            aes_block_n[WORDSIZE*cnt_r+i] = rd_block_data_i[i];
        end
      end
      //READ KEY: save the key coming from the memory to the internal register
      READ_KEY_S:
      begin
        rd_key_ready_o   = 1'b1;
        if (rd_key_valid_i)
        begin
          cnt_n          = cnt_r + 1;
          for(int i=0; i<WORDSIZE; i++)
            aes_key_n[WORDSIZE*cnt_r+i] = rd_key_data_i[i];
          if(cnt_r == AES_KEY_WORDS-1)
          begin
            cnt_n        = '0;
            fsm_ns       = WRITE_KEY_S;
          end
        end
      end
      //WRITE KEY: send the key to the internal accelerator
      WRITE_KEY_S:
      begin
        if(aes_ready_w)
        begin
          aes_init_w     = 1'b1;
          fsm_ns         = IDLE_S;
        end
      end
      //READ BLOCK: save the block coming from the memory to the internal register
      READ_BLOCK_S:
      begin
        rd_block_ready_o = 1'b1;
        if (rd_block_valid_i)
        begin
          cnt_n          = cnt_r + 1;
          for(int i=0; i<WORDSIZE; i++)
            aes_block_n[WORDSIZE*cnt_r+i] = rd_block_data_i[i];
          if(cnt_r == AES_BLOCK_WORDS-1)
          begin
            cnt_n        = '0;
            fsm_ns       = WRITE_BLOCK_S;
          end
        end
      end
      //WRITE BLOCK: send the block to the internal accelerator
      WRITE_BLOCK_S:
      begin
        if(aes_ready_w)
        begin
          //Start the AES
          aes_next_w     = 1'b1;
          fsm_ns         = READ_RESULT_S;
        end
      end
      //READ RESULT: save the result in an internal register
      READ_RESULT_S:
      begin
        //End of computation: save the result
        if (aes_valid_w)
        begin
          fsm_ns         =   WRITE_RESULT_S;
          aes_result_n   = aes_result_w;
        end
      end
      //WRITE RESULT: send the result to the memory
      WRITE_RESULT_S:
      begin
        wr_valid_o       = 1'b1;
        for(int i=0; i<WORDSIZE; i++)
            wr_data_o[i] = aes_result_n[WORDSIZE*cnt_r+i];
        if (wr_ready_i)
        begin
          cnt_n          =   cnt_r + 1;
          if(cnt_r == AES_BLOCK_WORDS-1)
          begin
            cnt_n        =   '0;
            fsm_ns       =   IDLE_S;
          end
        end
      end

      default:
      begin
        fsm_ns           =   IDLE_S  ;
      end
    endcase
  end

endmodule
