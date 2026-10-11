`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: San Jose State University
// Engineer: Amey Ashish Praveen
// 
// Create Date:    13:05:27 03/11/2015 
// Module Name:    alu_ctrl 
//////////////////////////////////////////////////////////////////////////////////
module alu_ctrl(
    input [1:0] alu_op,
    input [5:0] func,
    output reg [3:0] alu_ctrl,
    output reg jr,
    output reg shift_ren,
    output reg shift_len,
    output reg shift_data2reg
);

always @(*)
begin
    alu_ctrl = 4'b0000;
    jr = 1'b0;
    shift_ren = 0;
    shift_len = 0;
    shift_data2reg = 0;

    if(alu_op == 2'b00) begin
        alu_ctrl = 4'b0010; // load_word or store word
    end
    else if(alu_op == 2'b01) begin
        alu_ctrl = 4'b0110; // branch equal
    end
    else if(alu_op == 2'b10) begin
        case(func)
            6'b100000 : alu_ctrl = 4'b0010; // ADD
            6'b100010 : alu_ctrl = 4'b0110; // SUB
            6'b100100 : alu_ctrl = 4'b0000; // AND
            6'b100101 : alu_ctrl = 4'b0001; // OR
            6'b101010 : alu_ctrl = 4'b0111; // SLT
            6'b001000 : jr = 1'b1;
            6'b000000 : begin shift_len = 1; shift_data2reg = 1; end
            6'b000010 : begin shift_ren = 1; shift_data2reg = 1; end
            
            default: begin
                alu_ctrl = 4'b0000;
            end
        endcase
    end
end
 
endmodule
