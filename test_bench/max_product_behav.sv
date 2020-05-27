`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 03:27:57 PM
// Design Name: 
// Module Name: max_product_behav
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


module max_product_behav
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, STATES = 4, OUTPUT_SYMBOLS = 4, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[SYMBOLS][OUTPUT_SYMBOLS],
logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1],
output logic out_valid = 0,
output logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL][SYMBOLS] = '{ default : 0 }
);

localparam OUTPUT_BITS = trellis.OUTPUT_BITS;
localparam INPUT_SYMBOLS = trellis.INPUT_SYMBOLS;

typedef integer unsigned uint;
typedef logic [BITS-1:0] beta_t[STATES];
typedef logic [BITS-1:0] branch_metric_set_t[OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] branch_metric_array_t[SYMBOLS][OUTPUT_SYMBOLS];
typedef real llr_real_t[SYMBOLS][BITS_PER_SYMBOL];
typedef logic [BITS-1:0] llr_set_t[BITS_PER_SYMBOL];
typedef logic [BITS-1:0] llr_t[SYMBOLS][BITS_PER_SYMBOL];
typedef logic [BITS-1:0] llr_transpose_t[BITS_PER_SYMBOL][SYMBOLS];

float_math_if float_math();
logic [BITS-1:0] MINUS_INFINITY;

always @(posedge clk)
  begin
    out_valid <= 0;
    if (in_valid)
      out_valid <= 1;
  end

always @(posedge clk)
  begin
    LLR_D <= '{ default : 0 };
    if (in_valid)
      LLR_D <= BCJR_MaxProduct(branch_metric);
  end

function llr_t ComputeLLRs(llr_t llr_1, llr_t llr_0);
  llr_t llr_d;
  llr_t result;
  /* Compute a posteriori information [LLRs] */
  for (int i = 0; i < SYMBOLS; i++)
    for (int j = 0; j < BITS_PER_SYMBOL; j++)
      llr_d[i][j] = float_math.Subtract(llr_1[i][j], llr_0[i][j]);
  return llr_d;
endfunction

function void TrellisStep(int state, logic [BITS-1:0] branch_metric[OUTPUT_SYMBOLS], logic [BITS-1:0] AlphaMetric,
    beta_t oldBetaMetric, llr_set_t llr_0_In, llr_set_t llr_1_In,
    output beta_t BetaMetric, output llr_set_t llr_0, output llr_set_t llr_1);
  logic [BITS-1:0] metricInc, curMetric;
  logic [BITS-1:0] outputMetric;
  int bitValue;
  llr_0 = llr_0_In;
  llr_1 = llr_1_In;
  /* for each branch */
  for (int p = 0; p < INPUT_SYMBOLS; p++)
    begin /* for each branch */
      /* ---- Beta ------------- */
      int nextState;
      metricInc = branch_metric[trellis.outputs[state][p]];
      nextState = trellis.next_state[state][p];
      curMetric = float_math.Add(oldBetaMetric[nextState], metricInc);
      if (float_math.GreaterThan(curMetric, BetaMetric[state]) || (p == 0))
        BetaMetric[state] = curMetric;

      /* ---- output metric of current state ---- */
      outputMetric = float_math.Add(curMetric, AlphaMetric);

      /* ---- a posteriori LLR output calculation ---- */
      bitValue = trellis.outputs[state][p];
      for (int b = OUTPUT_BITS - 1; b >= 0; b--)
        begin
          int BitIdx;
          BitIdx = OUTPUT_BITS - 1 - b;
          if (bitValue >= (1 << b))
            begin /* bit is +1 */
              bitValue = bitValue - (1 << b);
              if (float_math.GreaterThan(outputMetric, llr_1[BitIdx]))
                llr_1[BitIdx] = outputMetric;
            end
          else
            begin /* bit is -1 */
              if (float_math.GreaterThan(outputMetric, llr_0[BitIdx]))
                llr_0[BitIdx] = outputMetric;
            end
        end
    end /* for p input symbols */
endfunction

llr_set_t llr_0_save[SYMBOLS], llr_1_save[SYMBOLS];

function void OneSymbolMaxProduct(int i, branch_metric_set_t branch_metric, beta_t oldBetaMetric, 
    output beta_t BetaMetric, output llr_set_t llr_0, output llr_set_t llr_1);
  llr_set_t llr_0_In;
  llr_set_t llr_1_In;
  llr_0 = '{ default : 0 };
  llr_1 = '{ default : 0 };
      
  /* ------------------ carry out one trellis step ------------------------- */
  for (int j = 0; j < trellis.STATES; j++)
    begin /* for each state */
      llr_0_In = llr_0;
      llr_1_In = llr_1;
      TrellisStep(j, branch_metric, AlphaMetric[j][i - 1], oldBetaMetric, llr_0_In, llr_1_In,
        BetaMetric, llr_0, llr_1);
    end   /* for j states */
  llr_0_save[i-1] = llr_0;
  llr_1_save[i-1] = llr_1;
endfunction

beta_t BetaMetricSave[SYMBOLS] = '{ default : 0 };

function llr_transpose_t BCJR_MaxProduct(branch_metric_array_t branch_metric_array);
  logic [BITS-1:0] result[BITS_PER_SYMBOL][SYMBOLS];
  beta_t BetaMetric;
  beta_t oldBetaMetric;
  llr_t llr_0, llr_1, llr_d;
  llr_set_t llr_0_set, llr_1_set;
  /* ------------------------------------------------------------------- */
  /* Beta-Metric (Backward Iteration)                                    */
  /* ------------------------------------------------------------------- */
  for (int j = 0; j < trellis.STATES; j++) 
    oldBetaMetric[j] = MINUS_INFINITY; //double.MaxValue;
  oldBetaMetric[0] = 0; // Test -- is non zero value necessary? $shortrealtobits(100000.0); /* Termination */
  for (int i = SYMBOLS; i > 0; i -= 1)
    begin
      OneSymbolMaxProduct(i, branch_metric_array[i-1], oldBetaMetric, BetaMetric, llr_0[i-1], llr_1[i-1]);
      oldBetaMetric = BetaMetric;
      BetaMetricSave[i-1] = BetaMetric;
    end

  llr_d = ComputeLLRs(llr_1, llr_0);
  for (int i = 0; i < SYMBOLS; i++)
    for (int j = 0; j < BITS_PER_SYMBOL; j++)
      result[j][i] = llr_d[i][j];
  return result;
endfunction

set_value
#(.BITS(BITS), .PRECISION(PRECISION), .VALUE("MIN"))
set_value_minus_infinity
(
.value(MINUS_INFINITY)
);

endmodule
