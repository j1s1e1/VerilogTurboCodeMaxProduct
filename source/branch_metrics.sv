`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 02:00:29 AM
// Design Name: 
// Module Name: branch_metrics
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


module branch_metrics
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, OUTPUT_SYMBOLS = 4)
(
input clk,
input in_valid,
input [BITS-1:0] symbol[BITS_PER_SYMBOL],
output logic out_valid,
output logic [BITS-1:0] branch_metric[OUTPUT_SYMBOLS]
);

logic out_valid_bm[OUTPUT_SYMBOLS];

assign out_valid = out_valid_bm[0];

for (genvar g = 0; g < OUTPUT_SYMBOLS; g++)
branch_metric
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .OUTPUT_SYMBOL(g))
branch_metric_array
(
.clk,
.in_valid,
.symbol,
.out_valid(out_valid_bm[g]),
.branch_metric(branch_metric[g])
);

endmodule
