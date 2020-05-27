`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 01:02:01 PM
// Design Name: 
// Module Name: alpha_element_behav
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


module alpha_element_behav
#(BITS = 16, PRECISION = "HALF", STATES = 4, BITS_PER_SYMBOL = 2)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[trellis.OUTPUT_SYMBOLS],
input logic [BITS-1:0] previousAlpha[STATES],
output logic out_valid = 0,
output logic [BITS-1:0] AlphaMetric[STATES] = '{ default : 0 } 
);

typedef logic [BITS-1:0] branch_metric_t[trellis.OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] alpha_t[STATES];

float_math_if float_math();
logic [BITS-1:0] MINUS_INFINITY;

always @(posedge clk)
  out_valid <= in_valid;
  
always @(posedge clk)
  if (in_valid)
    AlphaMetric <= CalcAlpha(branch_metric);

function alpha_t CalcAlpha(branch_metric_t branch_metric);
  logic [BITS-1:0] AlphaMetric[STATES];
  logic [BITS-1:0] result[STATES];
  /* ------------------------------------------------------------------- */
  /* Alpha-Metric (Forward Iteration)                                    */
  /* ------------------------------------------------------------------- */
  int tmp, q, b;
  for (int i = 0; i < STATES; i++)
    AlphaMetric[i] = MINUS_INFINITY;

  /* ------------------ carry out one trellis step ------------------------- */
  for (int j = 0; j < trellis.STATES; j++)
    begin                            /* for each to-state */
      logic [BITS-1:0] prevAlpha, curMetric;
      prevAlpha = previousAlpha[j];
      /* for each branch */
      for (int p = 0; p < trellis.INPUT_SYMBOLS; p++)
        begin                  /* for each branch */
           int nextState;
           curMetric = float_math.Add(prevAlpha, branch_metric[trellis.outputs[j][p]]);
           nextState = trellis.next_state[j][p];
           if (float_math.GreaterThan(curMetric, AlphaMetric[nextState]))
             AlphaMetric[nextState] = curMetric;
        end /* for p */
      end /* for j */
    for (int i = 0; i < trellis.STATES; i++)
     result[i] = AlphaMetric[i];
 return result;
  
endfunction

set_value
#(.BITS(BITS), .PRECISION(PRECISION), .VALUE("MIN"))
set_value_minus_infinity
(
.value(MINUS_INFINITY)
);

endmodule
