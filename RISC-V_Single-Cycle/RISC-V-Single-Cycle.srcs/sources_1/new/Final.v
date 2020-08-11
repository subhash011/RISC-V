`timescale 1ns / 1ps


module Final(input clk,[6:0] func7,opcode,[4:0] rs1,rs2,rd,[2:0] func3,[63:0] op1,op2,aluout,dmout,data,
[63:0] immediate,[63:0] pc);
    wire [6:0] func7,opcode;
    wire [4:0] rs1,rs2,rd;
    wire [2:0] func3;
    wire [63:0] op1,op2,aluout,dmout;
    wire [31:0] data;
    wire [63:0] immediate;
    wire [63:0] pc,writeval;
    wire [9:0] operation;
    wire ALUZero,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite,stop;
    wire [1:0] ALUOp;
    wire [63:0] secop,newpc;
    reg [3:0] counter;
    initial begin
        counter = 4'b0000;
    end
    always @ (posedge clk)
    begin
        if(counter == 4'b0101)
            counter = 0;        
        counter = counter + 4'b0001;
    end
    InstructionModule im(clk,pc,counter,data,stop);
    immediateGenerate ig(data,immediate);
    Decoder dc(clk,counter,data,func7,opcode,rs1,rs2,rd,func3,operation);
    control cntrl(data,opcode,ALUOp,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite);
    registerFile rm(clk,stop,RegWrite,counter,writeval,rs1,rs2,rd,op1,op2);
    programcounter pcount(counter,Branch,ALUZero,stop,data,immediate,op1,pc);
    alu al(clk,ALUSrc,stop,counter,rs2,op1,op2,immediate,pc,opcode,operation,func3,aluout,ALUZero);
    DataMemory dm(clk,MemRead,MemWrite,MemtoReg,counter,opcode,aluout,dmout,writeval,op2);
endmodule

module InstructionModule(input clk,input [63:0] pc,input [3:0] counter,output [31:0] data,output reg stop);
    integer file;
    integer scan;
    reg [31:0] data;
    reg [6:0] func7;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [2:0] func3;
    reg [4:0] rd;
    reg [6:0] opcode;
    reg [31:0] instructions [49:0];
    integer i = 0,j = 0;
    initial begin
        file = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V-Single-Cycle/input.txt","r");
        while(!$feof(file))
        begin
            scan = $fscanf(file,"%b\n",instructions[i]);
            i = i+1;
        end
        stop = 1'b0;
        j = i;
    end
    always @(posedge clk)
    begin
        if(counter == 4'b0001)
        begin
            if(pc/4 > j)
            begin
                stop = 1'b1;
            end
            else
            begin
                data <= instructions[pc/4];
            end
        end
    end   
endmodule

module immediateGenerate(input [31:0] data,output reg [63:0] immediate);
    reg [6:0] opcode;
    reg [11:0] imm_i;
    reg [11:0] imm_s,imm_jalr;
    reg [12:0] imm_b;
    reg [20:0] imm_u,imm_j;
    reg lbit = 1'b0;
    always @(*)
    begin
        opcode = data[6:0];
        if(opcode == 7'b1100011)// branch instructions
        begin
            imm_b = {data[31],data[7],data[30:25],data[11:8],lbit};
            immediate = $signed(imm_b);
        end
        else if(opcode == 7'b1101111)//jal
        begin
            imm_j = {data[31],data[19:12],data[20],data[30:21],lbit};
            immediate = $signed(imm_j);
        end
        else if(opcode == 7'b1100111)//jalr
        begin
            imm_jalr = data[31:20];
            immediate = $signed(imm_jalr);
        end
        else if(opcode ==  7'b0100011)//store word  
        begin
            imm_s = {data[31:25],data[11:7]};
            immediate = $signed(imm_s);
        end
        else if(opcode == 7'b0010011)//logical i    
        begin
            imm_i = {data[31:25],data[24:20]};
            immediate = $signed(imm_i);
        end
        else if(opcode == 7'b0000011)//load instructions
        begin
            imm_i = {data[31:20]};
            immediate = $signed(imm_i);
        end
    end
endmodule

module Decoder(input clk,input [3:0] counter,input [31:0] data,output reg [6:0] func7,opcode,output reg [4:0] 
rs1,rs2,rd,output reg [2:0] func3,output reg [9:0] operation);
    always @(posedge clk)
    begin
        if(counter == 4'b0010)
        begin
            func7 <= data[31:25];
            rs2 <= data[24:20];
            rs1 <= data[19:15];
            func3 <= data[14:12];
            rd <= data[11:7];
            opcode <= data[6:0];
            operation <= {data[31:25],data[14:12]};
        end
    end
endmodule

module control(input [31:0] data,input [6:0] opcode,output reg [1:0] ALUOp ,output reg Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite);
    always @ (opcode)
    begin
        case(opcode)
            7'b0110011:begin//R-Type Instructions
                       ALUOp = 2'b10;
                       Branch = 1'b0;
                       MemRead = 1'b0;
                       MemtoReg = 1'b0;
                       MemWrite = 1'b0;
                       ALUSrc = 1'b0;
                       RegWrite = 1'b1; 
                       end
           7'b0000011:begin// Load Double Word
                      ALUOp = 2'b00;
                      Branch = 1'b0;
                      MemRead = 1'b1;
                      MemtoReg = 1'b1;
                      MemWrite = 1'b0;
                      ALUSrc = 1'b1;
                      RegWrite = 1'b1;
                      end
          7'b0100011:begin//Store Double Word
                     ALUOp = 2'b00;
                     Branch = 1'b0;
                     MemRead = 1'b0;
                     MemWrite = 1'b1;
                     ALUSrc = 1'b1;
                     RegWrite = 1'b0;
                     end
          7'b1100011:begin//branch instructions
                     ALUOp = 2'b01;
                     Branch = 1'b1;
                     MemRead = 1'b0;
                     MemWrite = 1'b0;
                     ALUSrc = 1'b0;
                     RegWrite = 1'b0;
                     end
          7'b0010011:begin//logical i operations
                     ALUOp = 2'b00;
                     Branch = 1'b0;
                     MemRead = 1'b0;
                     MemWrite = 1'b0;
                     MemtoReg = 1'b0;
                     ALUSrc = 1'b1;
                     RegWrite = 1'b1;   
                     end 
          7'b1101111:begin//jal
                     ALUOp = 2'b00;
                     Branch = 1'b1;
                     MemRead = 1'b0;
                     MemWrite = 1'b0;
                     MemtoReg = 1'b0;
                     ALUSrc = 1'b1;
                     RegWrite = 1'b1;
                     end
           7'b1100111:begin//jalr
                     ALUOp = 2'b00;
                     Branch = 1'b1;
                     MemRead = 1'b0;
                     MemWrite = 1'b0;
                     MemtoReg = 1'b0;
                     ALUSrc = 1'b1;
                     RegWrite = 1'b1;
                     end     
        endcase
    end
endmodule

module programcounter(input [3:0] counter,input Branch,ALUZero,stop,input [31:0] data,input [63:0] immediate,op1,output reg [63:0] pc);
    initial begin
        pc = 64'b0;
    end
    always @ (*)
    begin
        if(counter == 4'b0100 && stop != 1'b1)
        begin
            if(Branch & ALUZero == 1'b1)
            begin
                if(data[6:0] == 7'b1100111)
                    pc = op1 + immediate;
                else
                    pc = pc + immediate;
            end
            else
            begin
                pc = pc + 64'd4;
            end
        end
    end
endmodule

module DataMemory(
    input clk,MemRead,MemWrite,MemtoReg,
    input [3:0] counter,
    input [6:0] opcode,
    input [63:0] aluout,
    output reg [63:0] dmout,writeval,
    input [63:0] op2
);  
    reg [63:0] register [31:0];
    reg [63:0] memory [49:0];
    integer  file,scan;
    always @ (posedge clk)
    begin
        if(counter == 4'b0100)
        begin
            if(MemRead == 1'b1)
            begin
                file = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V-Single-Cycle/memory.txt","r");
                for(integer i = 0;i<49;i = i+1)
                begin
                    scan = $fscanf(file,"%b\n",memory[i]);
                end
                dmout = memory[aluout];
                $fclose(file);
            end
            if(MemWrite == 1'b1)
            begin
                file = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V-Single-Cycle/memory.txt","r");
                for(integer i = 0;i<49;i = i+1)
                begin
                    scan = $fscanf(file,"%b\n",memory[i]);
                end
                $fclose(file);
                memory[aluout] = op2;
                file = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V-Single-Cycle/memory.txt","w");
                for(integer i=0;i<49;i = i+1)
                begin
                    $fwrite(file,"%b\n",memory[i]);
                end
                $fclose(file);
            end
            if(MemtoReg == 1'b0)
            begin
                writeval = aluout;
            end
            else
            begin
                writeval = dmout;
            end
        end
    end
endmodule

module registerFile(input clk,stop,RegWrite,input [3:0] counter,input [63:0] writeval,input [4:0] rs1,rs2,input [4:0] rd,output 
[63:0]op1,op2);
    reg [63:0] register [31:0];
    reg [63:0] op1,op2;
    integer file,scan,outf;
    always @ (posedge clk)
    begin
        if(counter == 4'b0011)
        begin
            file = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V-Single-Cycle/register.txt","r");
            for(integer i = 0;i<32;i = i+1)
            begin
                scan = $fscanf(file,"%b\n",register[i]);
            end
            $fclose(file);
            op1 <= register[rs1];
            op2 <= register[rs2];
        end
        if(counter == 4'b0101)
        begin
            if(RegWrite == 1'b1 && stop != 1'b1 && rd != 5'b0)
            begin
                outf = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V-Single-Cycle/register.txt","w");
                register[rd] = writeval;
                for(integer i = 0;i<32;i = i+1)
                begin
                    $fwrite(outf,"%b\n",register[i]);
                end
                $fclose(outf);
            end
        end
    end
endmodule


module alu(
    input clk,ALUSrc,stop,
    input [3:0] counter,
    input [4:0] rs2,
    input [63:0] op1,op2,immediate,pc,
    input [6:0] opcode,
    input [9:0] operation,
    input [2:0] func3,
    output reg [63:0]  aluout,
    output reg ALUZero
);
    wire [63:0] secop;
    initial begin
        ALUZero = 1'b0;
    end
    assign secop = (ALUSrc == 1'b0)?op2:immediate;
    always @ (*)
    begin
        if(counter == 4'b0011)
        begin
            ALUZero = 1'b0;
            if(opcode == 7'b0010011)
            begin
                if(func3 == 3'b000)//addi
                begin
                    aluout = op1 + secop;
                end
                else if(operation == 10'b0000000001)//slli
                begin
                    aluout = op1 << rs2;
                end
                else if(operation == 10'b0000000101)//srli
                begin
                    aluout = op1 >> rs2;
                end
                else if(operation == 10'b0100000101)//srai
                begin
                    aluout = op1 >>> rs2;
                end
                else if(func3 == 3'b100)//xori
                begin
                    aluout = op1 ^ immediate;
                end
                else if(func3 == 3'b110)//ori
                begin
                    aluout = op1 | immediate;
                end
                else if(func3 == 3'b111)//andi  
                begin
                    aluout = op1 & immediate;
                end
            end
            else if(opcode == 7'b0110011)//R-type  
            begin
                if(operation == 10'b0000000000)//add
                    aluout = op1+secop;
                else if(operation == 10'b0100000000)//sub
                    aluout = op1-secop;
                else if(operation == 10'b0000000111)//and
                    aluout = op1 & secop;
                else if(operation == 10'b0000000100)//xor
                    aluout = op1^secop;
                else if(operation == 10'b0000000110)//or
                    aluout = op1 | secop;
                else if(operation == 10'b0000000001)//sll
                    aluout = op1 << secop;
                else if(operation == 10'b0000000101)//srl
                    aluout = op1 >> secop;
                else if(operation == 10'b0000000101)//sra
                    aluout = op1 >>> secop;
                else if(operation == 10'b0000001000)
                    aluout = op1 * op2;
            end
            else if(opcode == 7'b0000011)
            begin
                if(func3 == 3'b011)//load double word
                begin
                    aluout = op1 + secop;
                end
                
            end
            else if(opcode == 7'b0100011)
            begin
                if(func3 == 3'b011)//store double word
                begin
                    aluout = op1 + secop;
                end
            end
            else if(opcode == 7'b1100011)//branch instructions
            begin
                if(func3 == 3'b000)//beq
                begin
                    if(op1 == op2)
                        ALUZero = 1'b1;
                    else
                        ALUZero = 1'b0;
                end
                else if(func3 == 3'b001)//bne
                begin
                    if(op1 != op2)
                        ALUZero = 1'b1;
                    else
                        ALUZero = 1'b0;
                end
                else if(func3 == 3'b100)//blt
                begin
                    if(op1 < op2)
                        ALUZero = 1'b1;
                    else
                        ALUZero = 1'b0;
                end
                else if(func3 == 3'b101)//bge
                begin
                    if(op1 >= op2)
                        ALUZero = 1'b1;
                    else
                        ALUZero = 1'b0;
                end
            end
            else if(opcode == 7'b1101111)//jal
            begin
                aluout = pc + 4;
                ALUZero = 1'b1;
            end
            else if(opcode == 7'b1100111)//jalr
            begin
                aluout = pc + 4;
                ALUZero = 1'b1;
            end
        end
    end
endmodule