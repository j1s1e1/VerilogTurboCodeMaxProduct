`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 11:34:28 AM
// Design Name: 
// Module Name: beta_element
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


module beta_element
#(BITS = 16, PRECISION = "HALF", STATES = 4)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[trellis.OUTPUT_SYMBOLS],
input logic [BITS-1:0] nextBeta[STATES],
output logic out_valid,
output logic [BITS-1:0] BetaMetric[STATES]
);

typedef logic [BITS-1:0] branch_metric_t[STATES][trellis.INPUT_SYMBOLS];
typedef logic [BITS-1:0] beta_t[STATES][trellis.INPUT_SYMBOLS];

branch_metric_t branch_metric_states;
beta_t next_beta_states;
logic out_valid_array[STATES];

for (genvar g = 0; g < STATES; g++)
  for (genvar h = 0; h < trellis.INPUT_SYMBOLS; h++)
    assign branch_metric_states[g][h] = branch_metric[trellis.branch_metric_selection[g][h]];

for (genvar g = 0; g < STATES; g++)
  for (genvar h = 0; h < trellis.INPUT_SYMBOLS; h++)
    assign next_beta_states[g][h] = nextBeta[trellis.next_state[g][h]];   

assign out_valid = out_valid_array[0];

for (genvar g = 0; g < STATES; g++)
alpha_element_state
#(.BITS(BITS), .PRECISION(PRECISION), .INPUT_SYMBOLS(trellis.INPUT_SYMBOLS))
alpha_element_state_array
(
.clk,
.in_valid,
.branch_metric(branch_metric_states[g]),    // Sort these in connections
.previousAlpha(next_beta_states[g]),    // Sort these in connections
.out_valid(out_valid_array[g]),
.AlphaMetric(BetaMetric[g]) 
);

endmodule
