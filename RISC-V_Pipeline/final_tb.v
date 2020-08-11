`timescale 1ns / 1ps


module final_tb();

reg clk;
wire [31:0] data;
wire [6:0] func7;
wire [4:0] rs2,rs1;
wire [2:0] func3;
wire [4:0] rd;
wire [6:0] opcode;
wire [63:0] op1,op2,aluout,dmout;
wire [63:0] pc;
wire [63:0] immediate;
Final dut(.clk(clk),.data(data), .func7(func7),.rs2(rs2),.rs1(rs1),.func3(func3),.rd(rd),.opcode(opcode),
            .op1(op1), .op2(op2), .aluout(aluout), .dmout(dmout), .pc(pc), .immediate(immediate));

initial begin
    clk = 0;
    forever #10
        clk = ~clk;
end

endmodule