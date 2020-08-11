`timescale 1ns / 1ps

//parameter ifidMSB = 95;
//parameter idexMSB = 268;
//parameter exmemMSB = 202;
//parameter memwbMSB = 127;
//,[6:0] func7,opcode,[4:0] rs1,rs2,rd,[2:0] func3,[63:0] op1,op2,aluout,dmout,data,
//[63:0] immediate,[63:0] pc
module Final(input clk);
    wire [6:0] func7,opcode;
    wire [4:0] rs1,rs2,rd;
    wire [2:0] func3;
    wire [63:0] op1,op2,aluout,dmout;
    wire [31:0] data;
    wire [63:0] immediate;
    wire [63:0] pc,writeval,pcimm;
    wire [9:0] operation;
    wire ALUZero,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite,stop,PCSrc;
    wire [1:0] ALUOp;
    wire [63:0] secop,newpc;
    wire [95:0] ifid_register;
    wire [288:0] idex_register;
    wire [202:0] exmem_register;
    wire [134:0] memwb_register;
//    InstructionModule im(clk,pc,data,stop,ifid_register);
    InstructionDecodeStage ids(clk, memwb_register, ifid_register, stop, idex_register,rd);
//    immediateGenerate ig(data,immediate,idex_register);
//    control cntrl(data,opcode,ALUOp,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite);
//    InstructionDecode rm(clk,memwb_register,ifid_register,stop,op1,op2,idex_register);
//    programcounter pcount(PCSrc,stop,data,pcimm,pc);
    alu al(clk,stop,idex_register,aluout,ALUZero,exmem_register);
    DataMemory dm(clk,exmem_register,dmout, memwb_register);
endmodule

module InstructionModule(input clk,input [63:0] pc,output [31:0] data,output reg stop, output reg [95:0] ifid_register);
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
        file = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V_PIPELINE/input.txt","r");
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
        if(pc/4 > j)
        begin
            stop = 1'b1;
        end
        else
        begin
            data = instructions[pc/4];
            //order : pc, data;
            ifid_register = {pc, data};
        end
    end   
endmodule

module InstructionDecode(input clk,input [134:0] memwb_register,input [95:0] ifid_register,input stop,output [63:0]op1,op2, output reg [6:0] opcode, output reg [9:0] operation);
    reg [63:0] register [31:0];
    reg [63:0] op1,op2, aluout, dmout, writeval;
    reg [31:0] data;
    reg [4:0] rs1,rs2;
    reg [4:0] rd;
    reg RegWrite, MemtoReg;
    integer file,scan,outf;
    always @ (posedge clk)
    begin
        RegWrite = memwb_register[134];
        data = ifid_register[31:0];
        rs2 = data[24:20];
        rs1 = data[19:15];
        rd = data[11:7];
        file = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V_PIPELINE/register.txt","r");
        for(integer i = 0;i<32;i = i+1)
        begin
            scan = $fscanf(file,"%b\n",register[i]);
        end
        $fclose(file);
        op1 = register[rs1];
        operation = {data[31:25], data[14:12]};
        opcode = data[6:0];
        if(opcode == 7'b0010011 && (operation == 10'b0000000001 || operation == 10'b0000000101 || operation == 10'b0100000101))
            op2 = rs2;
        else
            op2 = register[rs2];
        if(RegWrite == 1'b1 && stop != 1'b1 && rd != 5'b0)
        begin
            MemtoReg = memwb_register[133];
            aluout = memwb_register[132:69];
            dmout = memwb_register[68:5];
            rd = memwb_register[4:0];
            if(MemtoReg == 1'b0)
            begin
                writeval = aluout;
            end
            else
            begin
                writeval = dmout;
            end
            outf = $fopen("C:/Users/subha/Desktop/Subhash/Verilog/RISC-V_PIPELINE/register.txt","w");
            register[rd] = writeval;
            for(integer i = 0;i<32;i = i+1)
            begin
                $fwrite(outf,"%b\n",register[i]);
            end
            $fclose(outf);
        end
    end
endmodule

module alu(
    input clk,stop,
    input [288:0] idex_register,
    output reg [63:0]  aluout,
    output reg ALUZero,
    output reg [202:0] exmem_register
);
    initial begin
        ALUZero = 1'b0;
    end
    reg ALUOp,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite;
    reg [63:0]  op1,op2,immediate,pc,secop;
    reg [4:0] rd;
    reg [2:0] func3;
    reg [6:0] opcode;
    reg [9:0] operation;
    always @ (posedge clk)
    begin
        //{ALUOp,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite} = idex_register[268:261];
        //{pc, op1, op2, immediate} = {idex_register[255:0]};
        ALUOp = idex_register[268:267];
        Branch = idex_register[266];
        MemRead = idex_register[265];
        MemtoReg = idex_register[264];
        MemWrite = idex_register[263];
        ALUSrc = idex_register[262];
        RegWrite = idex_register[261];
        pc = idex_register[255:192];
        op1 = idex_register[191:128];
        op2 = idex_register[127:64];
        immediate = idex_register[63:0];
        rd = idex_register[260:256];
        func3 = idex_register[271:269];
        secop = (ALUSrc == 1'b0)?op2:immediate;
        opcode = idex_register[278:272];
        ALUZero = 1'b0;
        operation = idex_register[288:279];
        if(opcode == 7'b0010011)
        begin
            if(func3 == 3'b000)//addi
            begin
                aluout = op1 + secop;
            end
            else if(operation == 10'b0000000001)//slli
            begin
                aluout = op1 << op2;
            end
            else if(operation == 10'b0000000101)//srli
            begin
                aluout = op1 >> op2;
            end
            else if(operation == 10'b0100000101)//srai
            begin
                aluout = op1 >>> op2;
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
        pc = pc + immediate<<2;
        //order : Branch,MemRead,MemtoReg,MemWrite,RegWrite, pc, ALUZero, aluout, op2, rd
        exmem_register = {Branch,MemRead,MemtoReg,MemWrite,RegWrite,pc, ALUZero, aluout, op2, rd};
    end
endmodule

module DataMemory(
    input clk,
    input [202:0] exmem_register,
    output reg [63:0] dmout,
    output reg [134:0] memwb_register
);  
    reg Branch,MemRead,MemtoReg,MemWrite,RegWrite, ALUZero;
    reg [63:0] aluout, pc;
    reg [4:0] op2, rd;
    reg [63:0] register [31:0];
    reg [63:0] memory [49:0];
    integer  file,scan;
    always @ (posedge clk)
    begin
//        {Branch,MemRead,MemtoReg,MemWrite,RegWrite,pc, ALUZero, aluout, op2, rd} = exmem_register;
        Branch = exmem_register[202];
        MemRead = exmem_register[201];
        MemtoReg = exmem_register[200];
        MemWrite = exmem_register[199];
        RegWrite = exmem_register[198];
        pc = exmem_register[197:134];
        ALUZero = exmem_register[133];
        aluout = exmem_register[132:69];
        op2 = exmem_register[68:5];
        rd = exmem_register[4:0];
        if(MemRead == 1'b1)
        begin
            file = $fopen("C:/Users/subha/Desktop/Subhash/Verilo/RISC-V_PIPELINE/memory.txt","r");
            for(integer i = 0;i<49;i = i+1)
            begin
                scan = $fscanf(file,"%b\n",memory[i]);
            end
            dmout = memory[aluout];
            $fclose(file);
        end
        if(MemWrite == 1'b1)
        begin
            file = $fopen("C:/Users/subha/Desktop/Subhash/Verilo/RISC-V_PIPELINE/memory.txt","r");
            for(integer i = 0;i<49;i = i+1)
            begin
                scan = $fscanf(file,"%b\n",memory[i]);
            end
            $fclose(file);
            memory[aluout] = op2;
            file = $fopen("C:/Users/subha/Desktop/Subhash/Verilo/RISC-V_PIPELINE/memory.txt","w");
            for(integer i=0;i<49;i = i+1)
            begin
                $fwrite(file,"%b\n",memory[i]);
            end
            $fclose(file);
        end
        memwb_register = {RegWrite, MemtoReg,aluout, dmout, rd};
    end
endmodule

module programcounter(input PCSrc,stop,input [31:0] data,input [63:0] pcimm,output reg [63:0] pc);
    always @ (*)
    begin
        if(PCSrc == 1'b1)
        begin
            if(data[6:0] == 7'b1100111)
                //pc = op1 + immediate;
                pc = pcimm;
            else
                //pc = pc + immediate;
                pc = pcimm;
        end
        else
        begin
            pc = pc + 64'd4;
        end
    end
endmodule

module immediateGenerate(input [95:0] ifid_register,output reg [63:0] immediate);
    reg [6:0] opcode;
    reg [11:0] imm_i;
    reg [11:0] imm_s,imm_jalr;
    reg [12:0] imm_b;
    reg [20:0] imm_u,imm_j;
    reg lbit = 1'b0;
    reg [31:0] data;
    always @(*)
    begin
        data = ifid_register[31:0];
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

module control(input [95:0] ifid_register,output reg [1:0] ALUOp ,output reg Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite);
    always @ (ifid_register[6:0])
    begin
        case(ifid_register[6:0])
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