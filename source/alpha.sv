`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 01:38:13 PM
// Design Name: 
// Module Name: alpha
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


module alpha
#(BITS = 16, PRECISION = "HALF", STATES = 4, BITS_PER_SYMBOL = 2, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input [BITS-1:0] LLRVector[BITS_PER_SYMBOL][SYMBOLS],
output logic out_valid,
output logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1]
);

localparam NUMBITS = trellis.NOUT * SYMBOLS;
localparam numSymbols = NUMBITS / trellis.OUTPUT_BITS;
localparam DELAY_BMA = 1;

typedef logic [BITS-1:0] alpha_t[trellis.STATES][SYMBOLS+1];
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL][SYMBOLS];
typedef logic [BITS-1:0] symbol_t[BITS_PER_SYMBOL];

logic [BITS-1:0] branch_metric[SYMBOLS][trellis.OUTPUT_SYMBOLS];
logic out_valid_bma;
logic [BITS-1:0] bma_symbols[SYMBOLS][BITS_PER_SYMBOL];

for (genvar g = 0; g < SYMBOLS; g++)
  for (genvar h = 0; h < BITS_PER_SYMBOL; h++)
    assign bma_symbols[g][h] = LLRVector[h][g];

branch_metrics_array
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .OUTPUT_SYMBOLS(trellis.OUTPUT_SYMBOLS), .SYMBOLS(SYMBOLS))
branch_metrics_array1
(
.clk,
.in_valid,
.symbol(bma_symbols),
.out_valid(out_valid_bma),
.branch_metric
);

alpha_array
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS))
alpha_array1
(
.clk,
.trellis,
.in_valid(out_valid_bma),
.branch_metric,
.out_valid,
.AlphaMetric
);

endmodule
