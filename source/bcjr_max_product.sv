`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 07:05:52 AM
// Design Name: 
// Module Name: bcjr_max_product
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


module bcjr_max_product
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, STATES = 7, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input [BITS-1:0] LLRVector[BITS_PER_SYMBOL][SYMBOLS],
output logic out_valid,
output logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL][SYMBOLS]
);

localparam OUTPUT_SYMBOLS = trellis.OUTPUT_SYMBOLS;
localparam ALPHA_DELAY = 2 * SYMBOLS + 2;
localparam BRANCH_METRIC_DELAY = 1;

localparam NUMBITS = BITS_PER_SYMBOL * SYMBOLS;
localparam int numInputSymbols = 2 ** trellis.INPUT_BITS;
localparam numInputBits = trellis.INPUT_BITS;
localparam int numOutputSymbols = 2 ** trellis.OUTPUT_BITS;
localparam numOutputBits = trellis.OUTPUT_BITS;

localparam numSymbols = NUMBITS / numOutputBits;
  
typedef integer unsigned uint;
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL][SYMBOLS];
typedef logic [BITS-1:0] symbol_t[BITS_PER_SYMBOL];
typedef logic [BITS-1:0] branch_metric_array_t[SYMBOLS][OUTPUT_SYMBOLS];

logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1];  // One extra ??
logic out_valid_alpha;

logic [BITS-1:0] branch_metric[SYMBOLS][OUTPUT_SYMBOLS];
logic [BITS-1:0] branch_metric_d[SYMBOLS][OUTPUT_SYMBOLS];
logic out_valid_bma;
logic [BITS-1:0] bma_symbols[SYMBOLS][BITS_PER_SYMBOL];

for (genvar g = 0; g < SYMBOLS; g++)
  for (genvar h = 0; h < BITS_PER_SYMBOL; h++)
    assign bma_symbols[g][h] = LLRVector[h][g];

branch_metrics_array
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS), .SYMBOLS(SYMBOLS))
branch_metrics_array1
(
.clk,
.in_valid,
.symbol(bma_symbols),
.out_valid(out_valid_bma),
.branch_metric
);

alpha
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES), 
    .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS))
alpha1
(
.clk,
.trellis,
.in_valid,
.LLRVector,
.out_valid(out_valid_alpha),
.AlphaMetric
);

delay_m 
#(.DELAY(ALPHA_DELAY - BRANCH_METRIC_DELAY), .WIDTH(BITS), .R(SYMBOLS), .C(OUTPUT_SYMBOLS))
delay_bm
(
.clk(clk),
.a(branch_metric),
.c(branch_metric_d)
); 

max_product
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .STATES(STATES), 
    .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS), .SYMBOLS(SYMBOLS))
max_product1
(
.clk,
.trellis,
.in_valid(out_valid_alpha),
.branch_metric(branch_metric_d),
.AlphaMetric,
.out_valid,
.LLR_D
);

endmodule
