//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    divider.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

module divider #(
  parameter NBITS = 8
  )
  (
  input logic clk_i,
  input logic rst_i,
  input logic wr_valid_i,
  input logic [N_BITS-1:0] wr_dividend_i,
  input logic [N_BITS-1:0] wr_divider_i,
  output logic wr_ready_o,
  output logic rd_valid_o,
  output logic [N_BITS-1:0] rd_quotient_o,
  output logic [N_BITS-1:0] rd_remainder_o,
  input logic rd_ready_i
  );

  enum logic [1:0] {INIT, CALC, SEND} state;
  logic [(NBITS<<1)-1:0] A_aux, B_aux;
  logic [3:0]i;

  always_ff @(posedge clock)begin
    if(reset)begin
      i <= 0;
      A_aux <= '0;
      B_aux <= '0;
      quotient <= '0;
      state <= INIT;
      iReady <= 0;
      oValid <= 0;
    end

    else begin
      case(state)
        INIT:
        begin
          i <= NBITS-1;
          iReady <= 1;
          oValid <= 0;
          A_aux <= A;
          B_aux <= B;
          state <= CALC;
        end

        CALC:
        begin
          if(i < NBITS)begin
            if(A_aux >= (B_aux<<i))begin
              A_aux <= A_aux-(B_aux<<i);
              quotient[i] <= 1;
            end
            else
              quotient[i] <= 0;

            i <= i-1;
          end

          else begin
            remainder <= A_aux;
            state <= SEND;
            oValid <= 1;
          end
        end

        SEND: begin
          if(oReady)begin
            oValid <= 0;
            state <= INIT;
          end
          else
            state <= SEND;
        end
      endcase
    end
  end

endmodule
