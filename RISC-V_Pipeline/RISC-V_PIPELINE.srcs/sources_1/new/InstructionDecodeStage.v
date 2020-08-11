`timescale 1ns/1ps

module InstructionDecodeStage(input clk,input [134:0] memwb_register,input [95:0] ifid_register,input stop, output [288:0] idex_register, output [4:0] rd);
    assign rd = ifid_register[11:7];
    wire [63:0] op1,op2, immediate;
    wire [1:0] ALUOp;
    wire [6:0] opcode;
    wire [9:0] operation;
    InstructionDecode rm(clk,memwb_register,ifid_register,stop,op1,op2, opcode, operation);
    immediateGenerate ig(ifid_register,immediate);
    control cntrl(ifid_register,ALUOp,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite);
    //order :ALUOp,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite, rd,  pc, op1, op2, immediate
    assign idex_register = {operation,opcode,ifid_register[14:12],ALUOp, Branch, MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite, ifid_register[11:7],  ifid_register[95:32], op1, op2, immediate};
endmodule