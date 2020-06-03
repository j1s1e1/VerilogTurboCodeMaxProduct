`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2020 03:34:32 PM
// Design Name: 
// Module Name: stream_alpha
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


module stream_alpha
#(BITS = 16, PRECISION = "HALF", STATES = 4, BITS_PER_SYMBOL = 2, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input block_start,
input [BITS-1:0] branch_metric[trellis.OUTPUT_SYMBOLS],
output logic out_valid,
output logic [BITS-1:0] AlphaMetric[STATES]
);

logic [BITS-1:0] MINUS_INFINITY;
logic [BITS-1:0] AlphaMetricZero[STATES];
logic [BITS-1:0] nextAlphaMetric[STATES];
logic  [BITS-1:0] previousAlpha[STATES];

assign AlphaMetricZero[0] = 0;
for (genvar g = 1; g < STATES; g++)
  assign AlphaMetricZero[g] = MINUS_INFINITY;

for (genvar g = 0; g < STATES; g++) 
  assign previousAlpha[g] = (in_valid) ?
                                (block_start) ?
                                    AlphaMetricZero[g] :
                                    nextAlphaMetric[g] :
                                0;

assign out_valid = in_valid; // This gives us initial value and alpha1 - alphaN-1 alpha N not used                              

for (genvar g = 0; g < STATES; g++) 
  assign AlphaMetric[g] = (out_valid) ? previousAlpha[g] : 0;  // Last result not used, but initial value is
  

alpha_element
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES))
alpha_element1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.previousAlpha,
.out_valid(),
.AlphaMetric(nextAlphaMetric)
);

set_value
#(.BITS(BITS), .PRECISION(PRECISION), .VALUE("MIN"))
set_value_minus_infinity
(
.value(MINUS_INFINITY)
);

endmodule
