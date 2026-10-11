`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: San Jose State University
// Engineer: Amey Ashish Praveen
// 
// Create Date:    12:42:05 03/11/2015 
// Module Name:    mips_controller 
// Description:    Main control unit decoding the 6-bit opcode into CPU signals
//////////////////////////////////////////////////////////////////////////////////
module mips_controller(
    input  [5:0] opcode,
    output reg reg_dst,
    output reg jump,
    output reg branch,
    output reg mem_rd,
    output reg mem_wrt,
    output reg [1:0] alu_op,
    output reg mem2reg,
    output reg alu_src,
    output reg reg_write,
    output reg and_data2alu,
    output reg bne
);

always @(*) begin
    reg_dst      = 1'b0;
    jump         = 1'b0;
    branch       = 1'b0;
    mem_rd       = 1'b0;
    mem_wrt      = 1'b0;
    alu_op       = 2'b00;
    mem2reg      = 1'b0;
    alu_src      = 1'b0;
    reg_write    = 1'b0;
    and_data2alu = 1'b0;
    bne          = 1'b0;

    case (opcode)
        6'b000000: begin // R-format (ADD, SUB, AND, OR, SLT)
            reg_dst   = 1'b1; 
            reg_write = 1'b1; 
            alu_op    = 2'b10; 
        end 

        6'b100011: begin // Load Word (LW)
            alu_src   = 1'b1; 
            mem2reg   = 1'b1;  
            reg_write = 1'b1; 
            mem_rd    = 1'b1; 
            alu_op    = 2'b00; 
        end 

        6'b101011: begin // Store Word (SW)
            alu_src   = 1'b1; 
            mem_wrt   = 1'b1;  
            alu_op    = 2'b00;  
        end 

        6'b000100: begin // Branch on Equal (BEQ)
            branch    = 1'b1; 
            alu_op    = 2'b01; 
        end 

        6'b000101: begin // Branch on Not Equal (BNE)
            bne       = 1'b1; 
            alu_op    = 2'b01; 
        end 

        6'b000010: begin // Jump (J)
            jump      = 1'b1;  
        end 

        6'b001000: begin // Add Immediate (ADDI)
            reg_dst   = 1'b0; 
            alu_src   = 1'b1; 
            mem2reg   = 1'b0;  
            reg_write = 1'b1; 
            alu_op    = 2'b00; 
        end 

        6'b001100: begin // AND Immediate (ANDI)
            reg_dst      = 1'b0; 
            mem2reg      = 1'b0;  
            reg_write    = 1'b1; 
            alu_op       = 2'b10; 
            and_data2alu = 1'b1; 
        end 

        default: begin
            reg_dst      = 1'b0;
            jump         = 1'b0;
            branch       = 1'b0;
            mem_rd       = 1'b0;
            mem_wrt      = 1'b0;
            alu_op       = 2'b00;
            mem2reg      = 1'b0;
            alu_src      = 1'b0;
            reg_write    = 1'b0;
            and_data2alu = 1'b0;
            bne          = 1'b0;
        end
    endcase
end   

endmodule
