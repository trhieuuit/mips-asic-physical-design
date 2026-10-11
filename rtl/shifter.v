`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Trong Hieu Le
// 
// Create Date:    22:17:47 03/11/2015 
// Module Name:    shifter 
//////////////////////////////////////////////////////////////////////////////////
module shifter(
    input [31:0] datain,
    input [4:0] shftamt,
    output reg [31:0] data_out,
    input shift_len,
    input shift_ren
);

// Declare intermediate signals for the 5 multiplexer stages
reg [31:0] stg1, stg2, stg3, stg4, stg5;

always @(*) begin
    // Initialize default values to prevent inferred latches
    data_out = 32'd0;
    stg1 = 32'd0; stg2 = 32'd0; stg3 = 32'd0; stg4 = 32'd0; stg5 = 32'd0;

    if (shift_ren) begin
        // LOGICAL RIGHT SHIFT
        // Utilizing bit concatenation for constant shifts to generate 
        // a hardware-efficient Barrel Shifter instead of dynamic shifting.
        stg1 = shftamt[0] ? {1'b0,       datain[31:1]}  : datain;
        stg2 = shftamt[1] ? {2'b00,      stg1[31:2]}    : stg1;
        stg3 = shftamt[2] ? {4'h0,       stg2[31:4]}    : stg2;
        stg4 = shftamt[3] ? {8'h00,      stg3[31:8]}    : stg3;
        stg5 = shftamt[4] ? {16'h0000,   stg4[31:16]}   : stg4;
        data_out = stg5;
    end
    else if (shift_len) begin
        // LOGICAL LEFT SHIFT
        stg1 = shftamt[0] ? {datain[30:0], 1'b0}        : datain;
        stg2 = shftamt[1] ? {stg1[29:0],   2'b00}       : stg1;
        stg3 = shftamt[2] ? {stg2[27:0],   4'h0}        : stg2;
        stg4 = shftamt[3] ? {stg3[23:0],   8'h00}       : stg3;
        stg5 = shftamt[4] ? {stg4[15:0],   16'h0000}    : stg4;
        data_out = stg5;
    end
end

endmodule
