//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    Dual_Port_Dual_Clock_BRAM.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

//This is a dual clock BRAM. This file is taken from Xilinx documentation, with minor modifications to parameterize the width and the depth of the BRAM.
module dual_port_dual_clk_BRAM #(
    parameter   BRAM_WIDTH  =   32,
    parameter   BRAM_DEPTH  =   512
)(
    clka,
    clkb,
    ena,
    enb,
    wea,
    addra,
    addrb,
    dia,
    dob
);

localparam ADDR_WIDTH = $clog2(BRAM_DEPTH);

input clka,clkb,ena,enb,wea;
input [ADDR_WIDTH-1:0] addra,addrb;
input [BRAM_WIDTH-1:0] dia;
output [BRAM_WIDTH-1:0] dob;
reg [BRAM_WIDTH-1:0] ram [BRAM_DEPTH-1:0];
reg [BRAM_WIDTH-1:0] dob;

//At each clock cycle "a", the bram saves the input if the input port is enabled and the data is valid
always @(posedge clka)
begin
 if (ena)
   begin
     if (wea)
       ram[addra] <= dia;
   end
end

//At each clock cycle "b", the bram shows the data specified by the read address, if the read port is enabled
always @(posedge clkb)
begin
 if (enb)
   begin
     dob <= ram[addrb];
   end
end

endmodule
