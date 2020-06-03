`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 11:29:11 AM
// Design Name: 
// Module Name: stream_beta
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


module stream_beta
#(BITS = 16, PRECISION = "HALF", STATES = 4, BITS_PER_SYMBOL = 2, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input block_start,
input [BITS-1:0] branch_metric[trellis.OUTPUT_SYMBOLS],
output logic out_valid,
output logic [BITS-1:0] BetaMetric[STATES]
);

logic [BITS-1:0] MINUS_INFINITY;
logic [BITS-1:0]BetaMetricZero[STATES];
logic [BITS-1:0] PreviousBetaMetric[STATES];
logic  [BITS-1:0] nextBeta[STATES];

assign BetaMetricZero[0] = 0;
for (genvar g = 1; g < STATES; g++)
  assign BetaMetricZero[g] = MINUS_INFINITY;

for (genvar g = 0; g < STATES; g++) 
  assign nextBeta[g] = (in_valid) ?
                                (block_start) ?
                                    BetaMetricZero[g] :
                                    PreviousBetaMetric[g] :
                                0;

assign out_valid = in_valid; // This gives us initial value and alpha1 - alphaN-1 alpha N not used                              

for (genvar g = 0; g < STATES; g++) 
  assign BetaMetric[g] = (out_valid) ? nextBeta[g] : 0;  // Last result not used, but initial value is
  

beta_element
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES))
beta_element1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.nextBeta,
.out_valid(),
.BetaMetric(PreviousBetaMetric)
);

set_value
#(.BITS(BITS), .PRECISION(PRECISION), .VALUE("MIN"))
set_value_minus_infinity
(
.value(MINUS_INFINITY)
);

endmodule
