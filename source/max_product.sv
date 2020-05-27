`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2020 05:59:02 AM
// Design Name: 
// Module Name: max_product
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


module max_product
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, STATES = 4, OUTPUT_SYMBOLS = 4, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[SYMBOLS][OUTPUT_SYMBOLS],
logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1],
output logic out_valid,
output logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL][SYMBOLS]
);

localparam OUTPUT_BITS = trellis.OUTPUT_BITS;
localparam INPUT_SYMBOLS = trellis.INPUT_SYMBOLS;

typedef logic [BITS-1:0] beta_t[STATES];
typedef logic [BITS-1:0] branch_metric_set_t[OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] branch_metric_array_t[SYMBOLS][OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] llr_set_t[BITS_PER_SYMBOL];
typedef logic [BITS-1:0] llr_t[SYMBOLS][BITS_PER_SYMBOL];
typedef logic [BITS-1:0] llr_transpose_t[BITS_PER_SYMBOL][SYMBOLS];

logic [BITS-1:0] MINUS_INFINITY;

logic in_valid_array[SYMBOLS];
logic [BITS-1:0] alpha_metric_symbols[SYMBOLS][STATES];
logic [BITS-1:0] old_beta_metric_symbols[SYMBOLS][STATES];
logic [BITS-1:0] beta_metric_symbols[SYMBOLS][STATES];
logic out_valid_array[SYMBOLS];
llr_t llr_d_symbols;
llr_transpose_t llr_d_save = '{ default : 0 };
llr_transpose_t zero = '{ default : 0 };

for (genvar g = 0; g < SYMBOLS; g++)
  for (genvar h = 0; h < BITS_PER_SYMBOL; h++)
    always_latch
      llr_d_save[h][g] = (out_valid_array[SYMBOLS - 1 - g]) ? llr_d_symbols[g][h] : llr_d_save[h][g];

assign LLR_D = (out_valid) ? llr_d_save : zero;

for (genvar g = 0; g < SYMBOLS; g++)
  for (genvar h = 0; h < STATES; h++)
    assign alpha_metric_symbols[g][h] = AlphaMetric[h][g];

for (genvar h = 0; h < STATES; h++)
  assign old_beta_metric_symbols[SYMBOLS-1][h] = (h == 0) ? 0 : MINUS_INFINITY;

for (genvar g = 0; g < SYMBOLS - 1; g++)
  for (genvar h = 0; h < STATES; h++)   
    assign old_beta_metric_symbols[g][h] = beta_metric_symbols[g+1][h];

assign in_valid_array[0] = in_valid;
for (genvar g = 1; g < SYMBOLS; g++)
  assign in_valid_array[g] = out_valid_array[g-1];
  
assign out_valid = out_valid_array[SYMBOLS-1];

llr_set_t llr_0_save[SYMBOLS], llr_1_save[SYMBOLS];
beta_t BetaMetricSave[SYMBOLS] = '{ default : 0 };

for (genvar g = SYMBOLS; g > 0; g--)
max_product_symbol
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .STATES(STATES), .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS))
max_product_symbol_array
(
.clk,
.trellis,
.in_valid(in_valid_array[SYMBOLS - g]),
.branch_metric(branch_metric[g-1]),
.AlphaMetric(alpha_metric_symbols[g-1]),
.OldBetaMetric(old_beta_metric_symbols[g-1]),
.out_valid(out_valid_array[SYMBOLS - g]),
.BetaMetric(beta_metric_symbols[g-1]),
.LLR_D(llr_d_symbols[g-1])
);

set_value
#(.BITS(BITS), .PRECISION(PRECISION), .VALUE("MIN"))
set_value_minus_infinity
(
.value(MINUS_INFINITY)
);

endmodule
