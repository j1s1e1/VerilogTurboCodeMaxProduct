`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2020 10:50:36 PM
// Design Name: 
// Module Name: scale_matrix
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


module scale_matrix
#(BITS = 16, PRECISION = "HALF", QUARTERS = 3, R = 2, C = 2)
(
input clk,
input in_valid,
input [BITS-1:0] a[R][C],
output out_valid,
output [BITS-1:0] c[R][C]
);

logic out_valid_array[R];

assign out_valid = out_valid_array[0];

for (genvar g = 0; g < R; g++)
scale_vector
#(.BITS(BITS), .PRECISION(PRECISION), .QUARTERS(QUARTERS), .N(C))
scale_vector_array
(
.clk,
.in_valid,
.a(a[g]),
.out_valid(out_valid_array[g]),
.c(c[g])
);

endmodule
