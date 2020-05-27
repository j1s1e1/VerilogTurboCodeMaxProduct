`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/25/2020 06:22:37 AM
// Design Name: 
// Module Name: max_product_symbol_state
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


module max_product_symbol_state_test
#(BITS = 16, PRECISION = "HALF", INPUT_SYMBOLS = 2, OUTPUT_BITS = 2, STATE = 0)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[INPUT_SYMBOLS], // Assign in calling module
logic [BITS-1:0] AlphaMetric,  // Assign in calling module
logic [BITS-1:0] OldBetaMetric[INPUT_SYMBOLS],  // Assign in calling module
output logic out_valid = 0,
output logic [BITS-1:0] BetaMetric = 0,
output logic [BITS-1:0] llr_0_out[OUTPUT_BITS] = '{ default : 0 },
output logic [BITS-1:0] llr_1_out[OUTPUT_BITS] = '{ default : 0 }
);

typedef logic [BITS-1:0] llr_t[OUTPUT_BITS];
typedef logic [BITS-1:0] old_beta_t[INPUT_SYMBOLS];
typedef logic [BITS-1:0] sum_t[INPUT_SYMBOLS];
typedef logic [BITS-1:0] output_metric_t[INPUT_SYMBOLS];
typedef logic [BITS-1:0] beta_t;

logic out_valid_sum = 0;
logic [BITS-1:0] sum[INPUT_SYMBOLS] = '{ default :0 };
logic [BITS-1:0] output_metric[INPUT_SYMBOLS] = '{ default :0 };
logic out_valid_beta_metric = 0;
logic out_valid_output_metric[INPUT_SYMBOLS] = '{ default :0 };
logic out_valid_llr_0[OUTPUT_BITS];
logic out_valid_llr_1[OUTPUT_BITS];

always @(posedge clk) 
  out_valid <= out_valid_llr_0[0];

add_vector
#(.BITS(BITS), .PRECISION(PRECISION), .N(INPUT_SYMBOLS))
add_vector_array
(
.clk,
.in_valid,
.a(branch_metric),
.b(OldBetaMetric),
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
.out_valid(out_valid_beta_metric),
.c(BetaMetric)
);

for (genvar g = 0; g < INPUT_SYMBOLS; g++)
add
#(.BITS(BITS), .PRECISION(PRECISION))
add_output_metric_array
(
.clk,
.in_valid(out_valid_sum),
.a(sum[g]),
.b(AlphaMetric),
.out_valid(out_valid_output_metric[g]),
.c(output_metric[g])
);

// output metrics need to be assigned to proper output bits
// there should be an even number for each output bit
// for each states output transitions
//
// output metrics are shared for each output bit for that transition
//
// If there are only two transitions from each state, 
// there will be only one output that matches each bit
// so max should cancel to just set the value.

logic [BITS-1:0] llr_0_output_metrics[OUTPUT_BITS][INPUT_SYMBOLS/2];
logic [BITS-1:0] llr_1_output_metrics[OUTPUT_BITS][INPUT_SYMBOLS/2];

for (genvar g = 0; g < OUTPUT_BITS; g++)
  for (genvar h = 0; h < INPUT_SYMBOLS / 2; h++)
    begin
      assign llr_0_output_metrics[g][h] = output_metric[trellis.llr_0_bms[STATE][g][h]];
      assign llr_1_output_metrics[g][h] = output_metric[trellis.llr_1_bms[STATE][g][h]];
    end

for (genvar g = 0; g < OUTPUT_BITS; g++)
max_vector
#(.BITS(BITS), .PRECISION(PRECISION), .WIDTH(INPUT_SYMBOLS/2))
max_llr0_array
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_output_metric[0]),
.vector_a(llr_0_output_metrics[g]),
.out_valid(out_valid_llr_0[g]),
.c(llr_0_out[g])
);

for (genvar g = 0; g < OUTPUT_BITS; g++)
max_vector
#(.BITS(BITS), .PRECISION(PRECISION), .WIDTH(INPUT_SYMBOLS/2))
max_vector_llr1
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_output_metric[0]),
.vector_a(llr_1_output_metrics[g]),
.out_valid(out_valid_llr_1[g]),
.c(llr_1_out[g])
);

endmodule
