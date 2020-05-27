`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2020 05:59:02 AM
// Design Name: 
// Module Name: max_product
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


module max_product
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, SYMBOLS = 10)
(
input clk,
trellis_if trellis,
input in_valid,
input logic [BITS-1:0] branch_metric[SYMBOLS][OUTPUT_SYMBOLS],
logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1],
output logic out_valid = 0,
output logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL][SYMBOLS] = '{ default : 0 }
);

localparam STATES = trellis.STATES;
localparam OUTPUT_BITS = trellis.OUTPUT_BITS;
localparam OUTPUT_SYMBOLS = trellis.OUTPUT_SYMBOLS;

typedef integer unsigned uint;
typedef real branch_metric_t[OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] branch_metric_set_t[OUTPUT_SYMBOLS];
typedef logic [BITS-1:0] branch_metric_array_t[SYMBOLS][OUTPUT_SYMBOLS];
typedef real llr_real_t[SYMBOLS][BITS_PER_SYMBOL];
typedef logic [BITS-1:0] llr_t[SYMBOLS][BITS_PER_SYMBOL];


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
      llr_d[i][j] = $shortrealtobits( $bitstoshortreal(llr_1[i][j]) - $bitstoshortreal(llr_0[i][j]) );
  return llr_d;
endfunction

function void TrellisStep(int state, logic [BITS-1:0] branch_metric[OUTPUT_SYMBOLS], logic [BITS-1:0] AlphaMetric,
    real oldBetaMetric[trellis.STATES], branch_metric_t BetaMetricIn, real llr_0_In[BITS_PER_SYMBOL], real llr_1_In[BITS_PER_SYMBOL],
    output branch_metric_t BetaMetric, output real llr_0[BITS_PER_SYMBOL], output real llr_1[BITS_PER_SYMBOL]);
  real BMVector[OUTPUT_SYMBOLS];
  real metricInc, curMetric;
  real outputMetric;
  int bitValue;
  for (int j = 0; j < OUTPUT_SYMBOLS; j++)
    BMVector[j] = $bitstoshortreal(branch_metric[j]);
  BetaMetric = BetaMetricIn;
  llr_0 = llr_0_In;
  llr_1 = llr_1_In;
  /* for each branch */
  for (int p = 0; p < OUTPUT_SYMBOLS; p++)
    begin /* for each branch */
      /* ---- Beta ------------- */
      int nextState;
      metricInc = BMVector[trellis.outputs[state][p]];
      nextState = trellis.next_state[state][p];
      curMetric = oldBetaMetric[nextState] + metricInc;
      if ((curMetric > BetaMetric[state]) || (p == 0))
        BetaMetric[state] = curMetric;

      /* ---- output metric of current state ---- */
      outputMetric = curMetric + $bitstoshortreal(AlphaMetric);

      /* ---- a posteriori LLR output calculation ---- */
      bitValue = trellis.outputs[state][p];
      for (int b = OUTPUT_BITS - 1; b >= 0; b--)
        begin
          int BitIdx;
          BitIdx = OUTPUT_BITS - 1 - b;
          if (bitValue >= (1 << b))
            begin /* bit is +1 */
              bitValue = bitValue - (1 << b);
              if (outputMetric > llr_1[BitIdx])
                llr_1[BitIdx] = outputMetric;
            end
          else
            begin /* bit is -1 */
              if (outputMetric > llr_0[BitIdx])
                llr_0[BitIdx] = outputMetric;
            end
        end
    end /* for p input symbols */
endfunction

function void OneSymbolMaxProduct(branch_metric_set_t branch_metric, real oldBetaMetric[trellis.STATES], 
    output branch_metric_t BetaMetric, output [BITS-1:0] llr_0[BITS_PER_SYMBOL], output [BITS-1:0] llr_1[BITS_PER_SYMBOL], int i);
  branch_metric_t BetaMetricIn;
  real llr_0_In[BITS_PER_SYMBOL];
  real llr_1_In[BITS_PER_SYMBOL];
  real llr_0_real[BITS_PER_SYMBOL];
  real llr_1_real[BITS_PER_SYMBOL];
  BetaMetric = '{ default : 0 };
  llr_0_real = '{ default : 0 };
  llr_1_real = '{ default : 0 };
      
  /* ------------------ carry out one trellis step ------------------------- */
  for (int j = 0; j < trellis.STATES; j++)
    begin /* for each state */
      BetaMetricIn = BetaMetric;
      llr_0_In = llr_0_real;
      llr_1_In = llr_1_real;
      TrellisStep(j, branch_metric, AlphaMetric[j][i - 1], oldBetaMetric, BetaMetricIn, llr_0_In, llr_1_In,
        BetaMetric, llr_0_real, llr_1_real);
    end   /* for j states */
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    begin
      llr_0[i] = $shortrealtobits(llr_0_real[i]);
      llr_1[i] = $shortrealtobits(llr_0_real[i]);
    end
endfunction

function llr_t BCJR_MaxProduct(branch_metric_array_t branch_metric_array);
  llr_t result;
  int i, j;
  uint p;
  branch_metric_t BetaMetric;
  real oldBetaMetric[trellis.STATES];
  llr_t llr_0, llr_1, llr_d;

  /* ------------------------------------------------------------------- */
  /* Beta-Metric (Backward Iteration)                                    */
  /* ------------------------------------------------------------------- */
  for (j = 0; j < trellis.STATES; j++) 
    oldBetaMetric[j] = -10000000.0; //double.MaxValue;
  oldBetaMetric[0] = 100000.0; /* Termination */
  for (i = SYMBOLS; i > 0; i -= 1)
    begin
      OneSymbolMaxProduct(branch_metric_array[i-1], oldBetaMetric, BetaMetric, llr_0[i-1], llr_1[i-1], i);
      oldBetaMetric = BetaMetric;
    end

  result = ComputeLLRs(llr_1, llr_0);
  return result;
endfunction

endmodule
