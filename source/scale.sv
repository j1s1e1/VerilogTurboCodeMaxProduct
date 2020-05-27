`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 10:11:27 PM
// Design Name: 
// Module Name: scale
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


module scale
#(BITS = 16, PRECISION = "HALF", QUARTERS = 3)
(
input clk,
input in_valid,
input [BITS-1:0] a,
output out_valid,
output [BITS-1:0] c
);

localparam EXP_BITS = (PRECISION == "HALF") ? 5 : 8;
localparam MANTISSA_BITS = BITS-1-EXP_BITS;

logic [BITS-1:0] half;
logic [BITS-1:0] quarter;
logic [BITS-1:0] three_quarters;
logic [EXP_BITS-1:0] exponent;
logic [EXP_BITS-1:0] exponent_half;
logic [EXP_BITS-1:0] exponent_quarter;

assign exponent = a[BITS-2 -:EXP_BITS];
assign exponent_half = (exponent != 0) ? exponent - 1 : 0;
assign exponent_quarter = (exponent != 0) ? exponent - 2 : 0;
assign half = {a[BITS-1],exponent_half,a[MANTISSA_BITS-1:0]};
assign quarter = {a[BITS-1],exponent_quarter,a[MANTISSA_BITS-1:0]};
assign c = (QUARTERS == 3) ? three_quarters : 0;

add
#(.BITS(BITS), .PRECISION(PRECISION))
add1
(
.rstn(1'b1),
.clk,
.in_valid,
.a(half),
.b(quarter),
.out_valid,
.c(three_quarters)
);

endmodule
