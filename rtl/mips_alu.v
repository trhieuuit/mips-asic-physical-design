`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: San Jose State University
// Engineer: Amey Ashish Praveen
// 
// Create Date:    01:34:14 03/11/2015 
// Module Name:    mips_alu 
// Description:    32-bit Arithmetic Logic Unit for MIPS Processor
//////////////////////////////////////////////////////////////////////////////////
module mips_alu(
    input [3:0] alu_ctrl,
    input [31:0] in1,
    input [31:0] in2,
    output [31:0] alu_out, 
    output zero,
    output reg cout
);


reg [31:0] alu_result;


assign alu_out = alu_result;
assign zero = (alu_result == 32'd0);

always @(*) begin

    cout = 1'b0;
    alu_result = 32'd0;

    case (alu_ctrl)
        4'd0 : alu_result = in1 & in2;                      
        4'd1 : alu_result = in1 | in2;                     
        

        4'd2 : {cout, alu_result} = {1'b0, in1} + {1'b0, in2}; 
        
        4'd6 : alu_result = in1 - in2;                      
        4'd7 : alu_result = (in1 < in2) ? 32'd1 : 32'd0;    
        4'd12: alu_result = ~(in1 | in2);                  
        
        default : alu_result = 32'd0;                      
    endcase
end

endmodule
