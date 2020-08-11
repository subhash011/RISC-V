`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2020 21:36:29
// Design Name: 
// Module Name: InstructionFetchStage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module InstructionFetchStage(input clk);
    reg [63:0] pc;
    initial begin
        pc = 64'b0;
    end
    programcounter pcount(PCSrc,stop,data,pcimm,pc);
    InstructionModule im(clk,pc,data,stop,ifid_register);
endmodule
