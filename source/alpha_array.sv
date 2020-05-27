`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 04:16:12 AM
// Design Name: 
// Module Name: alpha_array
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


module alpha_array
#(BITS = 16, PRECISION = "HALF", STATES = 4, BITS_PER_SYMBOL = 2, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
logic [BITS-1:0] branch_metric[SYMBOLS][trellis.OUTPUT_SYMBOLS],
output logic out_valid = 0,
output logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1]
);

typedef logic [BITS-1:0] alpha_t[trellis.STATES][SYMBOLS+1];
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL][SYMBOLS];
typedef logic [BITS-1:0] branch_metric_t[SYMBOLS][trellis.OUTPUT_SYMBOLS];

logic [BITS-1:0] MINUS_INFINITY;

for (genvar g = 1; g < trellis.STATES; g++)
  assign AlphaMetric[g][0] = MINUS_INFINITY;
assign AlphaMetric[0][0] = 0;

logic in_valid_array[SYMBOLS+1];
logic out_valid_array[SYMBOLS+1];
logic [BITS-1:0] AlphaMetricTranspose[SYMBOLS+1][STATES];

assign in_valid_array[0] = 0; // Not used
assign out_valid_array[0] = 0; // Not used
assign in_valid_array[1] = in_valid;
for (genvar g = 2; g < SYMBOLS+1; g++)
  assign in_valid_array[g] = out_valid_array[g-1];

always @(posedge clk)
  out_valid <= out_valid_array[SYMBOLS];

always @(posedge clk)
  for (int i = 0; i < STATES; i++)
    for (int j = 1; j < SYMBOLS+1; j++)
      begin
        AlphaMetric[i][j] <= AlphaMetric[i][j];
        if (out_valid_array[j])
          AlphaMetric[i][j] <= AlphaMetricTranspose[j][i];
      end
      
for (genvar g = 0; g < STATES; g++)
  assign AlphaMetricTranspose[0][g] = AlphaMetric[g][0];
    
for (genvar g = 1; g < SYMBOLS+1; g++)
alpha_element
#(.BITS(BITS), .PRECISION(PRECISION))
alpha_element_array
(
.clk,
.trellis,
.in_valid(in_valid_array[g]),
.branch_metric(branch_metric[g-1]),
.previousAlpha(AlphaMetricTranspose[g-1]),
.out_valid(out_valid_array[g]),
.AlphaMetric(AlphaMetricTranspose[g])
);

set_value
#(.BITS(BITS), .PRECISION(PRECISION), .VALUE("MIN"))
set_value_minus_infinity
(
.value(MINUS_INFINITY)
);

endmodule
