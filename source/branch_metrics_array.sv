`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 03:29:14 AM
// Design Name: 
// Module Name: branch_metrics_array
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


module branch_metrics_array
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, OUTPUT_SYMBOLS = 4, SYMBOLS = 10)
(
input clk,
input in_valid,
input [BITS-1:0] symbol[SYMBOLS][BITS_PER_SYMBOL],
output logic out_valid,
output logic [BITS-1:0] branch_metric[SYMBOLS][OUTPUT_SYMBOLS]
);

logic out_valid_array[SYMBOLS];

assign out_valid = out_valid_array[0];

for (genvar g = 0; g < SYMBOLS; g++)
branch_metrics
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS))
branch_metrics1
(
.clk,
.in_valid,
.symbol(symbol[g]),
.out_valid(out_valid_array[g]),
.branch_metric(branch_metric[g])
);
endmodule
