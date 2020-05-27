`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 04:35:24 AM
// Design Name: 
// Module Name: alpha_element
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


module alpha_element
#(BITS = 16, PRECISION = "HALF", STATES = 4)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[trellis.OUTPUT_SYMBOLS],
input logic [BITS-1:0] previousAlpha[STATES],
output logic out_valid,
output logic [BITS-1:0] AlphaMetric[STATES]
);

typedef logic [BITS-1:0] branch_metric_t[STATES][trellis.INPUT_SYMBOLS];
typedef logic [BITS-1:0] alpha_t[STATES][trellis.INPUT_SYMBOLS];

branch_metric_t branch_metric_states;
alpha_t previous_alpha_states;
logic out_valid_array[STATES];

for (genvar g = 0; g < STATES; g++)
  for (genvar h = 0; h < trellis.INPUT_SYMBOLS; h++)
    assign branch_metric_states[g][h] = branch_metric[trellis.previous_state_bms[g][h]];

for (genvar g = 0; g < STATES; g++)
  for (genvar h = 0; h < trellis.INPUT_SYMBOLS; h++)
    assign previous_alpha_states[g][h] = previousAlpha[trellis.prev_state[g][h]];   

assign out_valid = out_valid_array[0];

for (genvar g = 0; g < STATES; g++)
alpha_element_state
#(.BITS(BITS), .PRECISION(PRECISION), .INPUT_SYMBOLS(trellis.INPUT_SYMBOLS))
alpha_element_state_array
(
.clk,
.in_valid,
.branch_metric(branch_metric_states[g]),    // Sort these in connections
.previousAlpha(previous_alpha_states[g]),    // Sort these in connections
.out_valid(out_valid_array[g]),
.AlphaMetric(AlphaMetric[g]) 
);

endmodule
