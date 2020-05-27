`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 03:37:57 PM
// Design Name: 
// Module Name: max_product_symbol
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


module max_product_symbol_test
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, STATES = 4, OUTPUT_SYMBOLS = 4)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[OUTPUT_SYMBOLS],
logic [BITS-1:0] AlphaMetric[STATES],
logic [BITS-1:0] OldBetaMetric[STATES],
output logic out_valid,
output logic [BITS-1:0] BetaMetric[STATES] = '{ default : 0 },
output logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL] = '{ default : 0 }
);

localparam OUTPUT_BITS = trellis.OUTPUT_BITS;
localparam INPUT_SYMBOLS = trellis.INPUT_SYMBOLS;

typedef logic [BITS-1:0] beta_t[STATES];
typedef logic [BITS-1:0] branch_metric_t[OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL];

llr_t llr_zeros = '{ default : 0 };

logic in_valid_mpss;
logic [BITS-1:0] branch_metric_mpss[STATES][INPUT_SYMBOLS];
logic [BITS-1:0] OldBetaMetric_mpss[STATES][INPUT_SYMBOLS];
logic out_valid_mpss[STATES];
logic [BITS-1:0] BetaMetric_mpss[STATES];
logic [BITS-1:0] llr_0_out_mpss[STATES][INPUT_SYMBOLS];
logic [BITS-1:0] llr_1_out_mpss[STATES][INPUT_SYMBOLS];

assign in_valid_mpss = in_valid;

for (genvar g = 0; g < STATES; g++)
  for (genvar h = 0; h < INPUT_SYMBOLS; h++)
    begin
      assign branch_metric_mpss[g][h] = branch_metric[trellis.outputs[g][h]];
      assign OldBetaMetric_mpss[g][h] = OldBetaMetric[trellis.next_state[g][h]];
    end

for (genvar g = 0; g < STATES; g++)
max_product_symbol_state_test
#(.BITS(BITS), .PRECISION(PRECISION), .INPUT_SYMBOLS(INPUT_SYMBOLS), 
        .OUTPUT_BITS(OUTPUT_BITS), .STATE(g))
max_product_symbol_state_test_array
(
.clk,
.trellis,
.in_valid(in_valid_mpss),
.branch_metric(branch_metric_mpss[g]), // Assign in calling module
.AlphaMetric(AlphaMetric[g]),  // Assign in calling module
.OldBetaMetric(OldBetaMetric_mpss[g]),  // Assign in calling module
.out_valid(out_valid_mpss[g]),
.BetaMetric(BetaMetric_mpss[g]),
.llr_0_out(llr_0_out_mpss[g]),
.llr_1_out(llr_1_out_mpss[g])
);

logic [BITS-1:0] llr_0_out_mpss_transpose[INPUT_SYMBOLS][STATES];
logic [BITS-1:0] llr_1_out_mpss_transpose[INPUT_SYMBOLS][STATES];
logic out_valid_llr_0_max[INPUT_SYMBOLS];
logic out_valid_llr_1_max[INPUT_SYMBOLS];
logic [BITS-1:0] llr_0_max[INPUT_SYMBOLS];
logic [BITS-1:0] llr_1_max[INPUT_SYMBOLS];

for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
  for (genvar h = 0; h < STATES; h++)
    begin
      assign llr_0_out_mpss_transpose[g][h] = llr_0_out_mpss[h][g];
      assign llr_1_out_mpss_transpose[g][h] = llr_1_out_mpss[h][g];
    end
    
for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
max_vector
#(.BITS(BITS), .PRECISION(PRECISION), .WIDTH(STATES))
max_vector_llr0
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_mpss[0]),
.vector_a(llr_0_out_mpss_transpose[g]),
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
.in_valid(out_valid_mpss[0]),
.vector_a(llr_1_out_mpss_transpose[g]),
.out_valid(out_valid_llr_1_max[g]),
.c(llr_1_max[g])
);

logic out_valid_array[BITS_PER_SYMBOL];

assign out_valid = out_valid_array[0];

always @(posedge clk)
  begin
    BetaMetric <= BetaMetric;
    for (int i = 0; i < STATES; i++)
      if (out_valid_mpss[i])
        BetaMetric[i] <= BetaMetric_mpss[i];
  end

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
