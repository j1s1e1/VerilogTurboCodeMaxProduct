`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2020 10:49:22 PM
// Design Name: 
// Module Name: scale_vector
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


module scale_vector
#(BITS = 16, PRECISION = "HALF", QUARTERS = 3, N = 10)
(
input clk,
input in_valid,
input [BITS-1:0] a[N],
output out_valid,
output [BITS-1:0] c[N]
);

logic out_valid_array[N];

assign out_valid = out_valid_array[0];

for (genvar g = 0; g < N; g++)
scale
#(.BITS(BITS), .PRECISION(PRECISION), .QUARTERS(QUARTERS))
scale_array
(
.clk,
.in_valid,
.a(a[g]),
.out_valid(out_valid_array[g]),
.c(c[g])
);

endmodule
