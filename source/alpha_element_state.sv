`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 01:21:29 PM
// Design Name: 
// Module Name: alpha_element_state
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


module alpha_element_state
#(BITS = 16, PRECISION = "HALF", INPUT_SYMBOLS = 2)
(
input clk,
input in_valid,
input logic [BITS-1:0] branch_metric[INPUT_SYMBOLS],    // Sort these in connections
input logic [BITS-1:0] previousAlpha[INPUT_SYMBOLS],    // Sort these in connections
output logic out_valid,
output logic [BITS-1:0] AlphaMetric
);

logic [BITS-1:0] sum[INPUT_SYMBOLS];
logic out_valid_sum;

add_vector
#(.BITS(BITS), .PRECISION(PRECISION), .N(INPUT_SYMBOLS))
add_vector1
(
.clk,
.in_valid,
.a(branch_metric),
.b(previousAlpha),
.out_valid(out_valid_sum),
.c(sum)
);

max_vector
#(.BITS(BITS), .PRECISION(PRECISION), .WIDTH(INPUT_SYMBOLS))
max_vector1
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_sum),
.vector_a(sum),
.out_valid,
.c(AlphaMetric)
);

endmodule
