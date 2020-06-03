`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2020 05:46:53 PM
// Design Name: 
// Module Name: stream_max_product
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


module stream_max_product
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, STATES = 4, OUTPUT_SYMBOLS = 4, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input [BITS-1:0] branch_metric[OUTPUT_SYMBOLS],
input [BITS-1:0] AlphaMetric[STATES],
input [BITS-1:0] BetaMetric[STATES],
output logic out_valid,
output logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL]
);


localparam OUTPUT_BITS = trellis.OUTPUT_BITS;
localparam INPUT_SYMBOLS = trellis.INPUT_SYMBOLS;

typedef logic [BITS-1:0] beta_t[STATES];
typedef logic [BITS-1:0] branch_metric_t[OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL];

llr_t llr_zeros = '{ default : 0 };

logic in_valid_smps;
logic [BITS-1:0] branch_metric_smps[STATES][INPUT_SYMBOLS];
logic [BITS-1:0] BetaMetric_smps[STATES][INPUT_SYMBOLS];
logic out_valid_smps[STATES];
logic [BITS-1:0] llr_0_out[STATES][INPUT_SYMBOLS];
logic [BITS-1:0] llr_1_out[STATES][INPUT_SYMBOLS];

assign in_valid_smps = in_valid;

for (genvar g = 0; g < STATES; g++)
  for (genvar h = 0; h < INPUT_SYMBOLS; h++)
    begin
      assign branch_metric_smps[g][h] = branch_metric[trellis.outputs[g][h]];
      assign BetaMetric_smps[g][h] = BetaMetric[trellis.next_state[g][h]];
    end


for (genvar g = 0; g < STATES; g++)
stream_max_product_state
#(.BITS(BITS), .PRECISION(PRECISION), .INPUT_SYMBOLS(INPUT_SYMBOLS), 
        .OUTPUT_BITS(OUTPUT_BITS), .STATE(g))
stream_max_product_state_array
(
.clk,
.trellis,
.in_valid(in_valid_smps),
.branch_metric(branch_metric_smps[g]),
.AlphaMetric(AlphaMetric[g]),
.BetaMetric(BetaMetric_smps[g]),
.out_valid(out_valid_smps[g]),
.llr_0_out(llr_0_out[g]),
.llr_1_out(llr_1_out[g])
);

logic [BITS-1:0] llr_0_out_transpose[INPUT_SYMBOLS][STATES];
logic [BITS-1:0] llr_1_out_transpose[INPUT_SYMBOLS][STATES];
logic out_valid_llr_0_max[INPUT_SYMBOLS];
logic out_valid_llr_1_max[INPUT_SYMBOLS];
logic [BITS-1:0] llr_0_max[INPUT_SYMBOLS];
logic [BITS-1:0] llr_1_max[INPUT_SYMBOLS];

for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
  for (genvar h = 0; h < STATES; h++)
    begin
      assign llr_0_out_transpose[g][h] = llr_0_out[h][g];
      assign llr_1_out_transpose[g][h] = llr_1_out[h][g];
    end


for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
max_vector
#(.BITS(BITS), .PRECISION(PRECISION), .WIDTH(STATES))
max_vector_llr0
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_smps[0]),
.vector_a(llr_0_out_transpose[g]),
.out_valid(out_valid_llr_0_max[g]),
.c(llr_0_max[g])
);

for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
max_vector
#(.BITS(BITS), .PRECISION(PRECISION), .WIDTH(STATES))
max_vector_llr1
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_smps[0]),
.vector_a(llr_1_out_transpose[g]),
.out_valid(out_valid_llr_1_max[g]),
.c(llr_1_max[g])
);

logic out_valid_array[BITS_PER_SYMBOL];

assign out_valid = out_valid_array[0];


for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
 subtract
#(.BITS(BITS), .PRECISION(PRECISION))
subtract_array
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_llr_0_max[0]),
.a(llr_1_max[g]),
.b(llr_0_max[g]),
.out_valid(out_valid_array[g]),
.c(LLR_D[g])
);

endmodule
