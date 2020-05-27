`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 02:51:10 PM
// Design Name: 
// Module Name: alpha_element_state_behav
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


module alpha_element_state_behav
#(BITS = 16, PRECISION = "HALF", INPUT_SYMBOLS = 2)
(
input clk,
input in_valid,
input logic [BITS-1:0] branch_metric[INPUT_SYMBOLS],    // Sort these in connections
input logic [BITS-1:0] previousAlpha[INPUT_SYMBOLS],    // Sort these in connections
output logic out_valid = 0,
output logic [BITS-1:0] AlphaMetric = '{ default : 0 } 
);

typedef logic [BITS-1:0] branch_metric_t[INPUT_SYMBOLS];
typedef logic [BITS-1:0] alpha_t;

float_math_if float_math();

always @(posedge clk)
  out_valid <= in_valid;
  
always @(posedge clk)
  if (in_valid)
    AlphaMetric <= CalcAlpha(branch_metric);

function alpha_t CalcAlpha(branch_metric_t branch_metric);
  logic [BITS-1:0] AlphaMetric;
  logic [BITS-1:0] curMetric;
  /* ------------------------------------------------------------------- */
  /* Alpha-Metric (Forward Iteration)                                    */
  /* ------------------------------------------------------------------- */
  int tmp, q, b;

  /* ------------------ carry out one trellis step ------------------------- */

  /* for each branch */
  for (int p = 0; p < INPUT_SYMBOLS; p++)
    begin                  /* for each branch */
       curMetric = float_math.Add(previousAlpha[p], branch_metric[p]);
       if (float_math.GreaterThan(curMetric, AlphaMetric) || (p == 0))
         AlphaMetric = curMetric;
    end /* for p */
 return AlphaMetric; 
endfunction

endmodule
