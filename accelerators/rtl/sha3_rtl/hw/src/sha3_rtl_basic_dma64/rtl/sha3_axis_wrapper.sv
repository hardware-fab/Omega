// ============================================================================
// Project:   Sha3
// Authors:   Gabriele Montanaro, Andrea Galimberti, Davide Zoni
//
// Description:
//
// The SHA-3 SystemVerilog design implements the SHA-3-256, -384 and -512
// instances of the SHA-3 cryptographic hash function.
// The digest size, of either 256, 384 or 512 bits, can be configured by properly
// setting the SHA3_DIGEST_SIZE package parameter.
// The design makes use of a Keccak SystemVerilog implementation
// (https://github.com/jmoles/keccak-verilog), freely available on Github under
// the MIT license.
//
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
// Module: sha3_axis_wrapper
// Description: an axi-stream wrapper for the sha3 design
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

module sha3_axis_wrapper
  (
    input  logic          clk_i,
    input  logic          rst_i,
    //Input data channel - reading from memory
    input  logic[64-1:0]  rd_data_i,
    input  logic          rd_valid_i,
    output logic          rd_ready_o,
    //Output data channel - writing to memory
    output logic [64-1:0] wr_data_o,
    output logic          wr_valid_o,
    input  logic          wr_ready_i,
    //Start signal
    input  logic          start_i
  );

  import pkg_sha3::*;

//////////////////////////////////////////////////////////////////////////////
//    internal wires                                //
//////////////////////////////////////////////////////////////////////////////

  logic                           keccak_start_w;
  logic [SHA3_BRAM_DW - 1:0]      keccak_dataIn_w;
  logic                           keccak_validIn_w;
  logic                           keccak_last_w;
  logic                           keccak_full_w;
  logic                           keccak_ready_w;
  logic [SHA3_BRAM_DW - 1:0]      keccak_dataOut_w;
  logic                           keccak_validOut_w;

  logic [$clog2(SHA3_RATE_LINES) - 1:0] cnt_n, cnt_r;

  logic [SHA3_DIGEST_LINES-1:0][SHA3_BRAM_DW - 1:0]      sha3_digest_n, sha3_digest_r;

  typedef enum logic  [2:0]
  {
    IDLE_S           =  'd0,
    GET_MSG_S        =  'd1,
    COMPUTE_S        =  'd2,
    SAVE_HASH_S      =  'd3,
    SEND_OUTPUT_S    =  'd4
  } state_t;

  state_t fsm_cs, fsm_ns;

//////////////////////////////////////////////////////////////////////////////
//    internal submodules                           //
//////////////////////////////////////////////////////////////////////////////

  keccak #(
    .DIGEST_SIZE    (SHA3_DIGEST_SIZE),
    .CAPACITY       (SHA3_CAPACITY),
    .RATE           (SHA3_RATE)
  ) keccak (
    .Clock          (clk_i),
    .Reset          (rst_i),
    .Start          (keccak_start_w),
    .Din            (keccak_dataIn_w),
    .Din_valid      (keccak_validIn_w),
    .Last_block     (keccak_last_w),
    .Buffer_full    (keccak_full_w),
    .Ready          (keccak_ready_w),
    .Dout           (keccak_dataOut_w),
    .Dout_valid     (keccak_validOut_w)
  );

//////////////////////////////////////////////////////////////////////////////
//      wire assignments                                       //
//////////////////////////////////////////////////////////////////////////////

  assign   keccak_dataIn_w   =   rd_data_i;
  assign   keccak_validIn_w  =   rd_valid_i;
  assign   keccak_start_w    =   rst_i;   //Keccak start wire is actually a kind of reset
  assign   rd_ready_o        =   ~keccak_full_w;

//////////////////////////////////////////////////////////////////////////////
//      sequential logic                                       //
//////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i)
  begin
    if (rst_i)
    begin
      fsm_cs            <=   IDLE_S  ;
      cnt_r             <=   '0;
      sha3_digest_r     <=   '0;
    end
    else
    begin
      fsm_cs            <=   fsm_ns;
      cnt_r             <=   cnt_n;
      sha3_digest_r     <=   sha3_digest_n;
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
    sha3_digest_n      =   sha3_digest_r;

    //Wires
    keccak_last_w      =   1'b0;

    //Outputs
    wr_valid_o         =   1'b0;
    wr_data_o          =   '0;

    case (fsm_cs)
      //IDLE: sha is waiting to start operation
      IDLE_S:
      begin
        // Compute output
        if (start_i)
          fsm_ns       =   COMPUTE_S;
        // Valid data arrives
        else if (rd_valid_i)
          fsm_ns       =   GET_MSG_S;
      end
      //GET MSG: data is coming from the memory
      GET_MSG_S:
      begin
        // Compute output
        if (start_i)
          fsm_ns       =   COMPUTE_S;
      end
      //COMPUTE: compute state
      COMPUTE_S:
      begin
        //End of computation: save the result
        if (keccak_ready_w && ~keccak_full_w)
        begin
          fsm_ns           =   SAVE_HASH_S;
          keccak_last_w    =   1'b1;
        end
      end
      //SAVE HASH: save the digest in a register
      //(internal keccak module has no flow control, so it is necessary to save
      //the result before starting an AXI-stream communication
      SAVE_HASH_S:
      begin
        //If the data out is valid, save it and increment the counter
        if (keccak_validOut_w)
        begin
          cnt_n                   =   cnt_r + 1;
          sha3_digest_n[cnt_r]    =   keccak_dataOut_w;
          //Make the result available to the output
          if(cnt_r == SHA3_DIGEST_LINES-1)
          begin
            cnt_n                 =   '0;
            fsm_ns                =   SEND_OUTPUT_S;
          end
        end
      end
      //SEND OUTPUT: send the result with an axi-stream protocol
      SEND_OUTPUT_S:
      begin
        wr_valid_o        =   1'b1;
        wr_data_o         =   sha3_digest_r[cnt_r];
        //If the receiver is ready, increment the counter
        if(wr_ready_i)
        begin
          cnt_n           =   cnt_r + 1;
          //Return to IDLE state when finished
          if(cnt_r == SHA3_DIGEST_LINES-1)
          begin
            cnt_n         =   '0;
            fsm_ns        =   IDLE_S;
          end
        end
      end

      default:
      begin
        fsm_ns             =   IDLE_S  ;
      end
    endcase
  end

endmodule
