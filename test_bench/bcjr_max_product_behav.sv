`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 07:06:20 AM
// Design Name: 
// Module Name: bcjr_max_product_behav
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


module bcjr_max_product_behav
#(BITS_PER_SYMBOL = 2, SYMBOLS = 10)
(
trellis_if trellis,
input in_valid,
input real LLRVector[BITS_PER_SYMBOL][SYMBOLS],
output logic out_valid,
output real LLR_D[BITS_PER_SYMBOL][SYMBOLS]
);

localparam NUMBITS = BITS_PER_SYMBOL * SYMBOLS;
localparam int numInputSymbols = 2 ** trellis.INPUT_BITS;
localparam numInputBits = trellis.INPUT_BITS;
localparam int numOutputSymbols = 2 ** trellis.OUTPUT_BITS;
localparam numOutputBits = trellis.OUTPUT_BITS;

localparam numSymbols = NUMBITS / numOutputBits;

assign out_valid = in_valid;

always_comb
  if (in_valid)
    LLR_D = BCJR_MaxProduct(LLRVector);
  
typedef integer unsigned uint;
typedef real llr_t[BITS_PER_SYMBOL][SYMBOLS];

real AlphaMetric[trellis.STATES][SYMBOLS+1];  // One extra ??
real BetaMetricSave[SYMBOLS][trellis.STATES] = '{ default : 0 };
real llr_0_save[NUMBITS], llr_1_save[NUMBITS];

function llr_t BCJR_MaxProduct(llr_t LLRVector);
  llr_t result;
  int i, j;
  uint p;
  real BMVector[numOutputSymbols];

  real BetaMetric[trellis.STATES];
  real oldBetaMetric[trellis.STATES];
  real llr_0[NUMBITS], llr_1[NUMBITS], llr_d[NUMBITS];
  llr_0 = '{ default : 0 };
  llr_1 = '{ default : 0 };
  llr_d = '{ default : 0 };

  /* ------------------------------------------------------------------- */
  /* Alpha-Metric (Forward Iteration)                                    */
  /* ------------------------------------------------------------------- */
            
  // By definition, we start in state 0. In order to make this clear
  // ** to the BCJR, we severely discriminate against all other states... 

  for (i = 0; i < trellis.STATES; i++)
    for (j = 0; j < numSymbols + 1; j++)
      AlphaMetric[i][j] = -10000000.0; //double.MaxValue;

  AlphaMetric[0][0] = 100000.0;

  for (i = 0; i < numSymbols; i += 1)
    begin
      int tmp, q, b;
      /* precompute the Branch Metric for each output Symbol, based on the LLRs */
      for (q = 0; q < numOutputSymbols; q++)
        begin
          BMVector[q] = 0.0;
          tmp = q;
          for (b = numOutputBits - 1; b >= 0; b--)
            begin
              if (tmp >= (1 << b))
                begin
                  tmp = tmp - (1 << b);
                  BMVector[q] += LLRVector[b][i];   /* first bit is MSB */
                end
              else
                begin
                  BMVector[q] -= LLRVector[b][i];   /* first bit is MSB */
                end
            end
          /* adjust to max-log metric */
          BMVector[q] = 0.5 * BMVector[q];
        end

      /* ------------------ carry out one trellis step ------------------------- */
      for (j = 0; j < trellis.STATES; j++)
        begin                            /* for each to-state */
          real prevAlpha, curMetric;
          prevAlpha = AlphaMetric[j][i];
          /* for each branch */
          for (p = 0; p < numInputSymbols; p++)
            begin                  /* for each branch */
              int nextState;
              curMetric = prevAlpha + BMVector[trellis.outputs[j][p]];
              nextState = trellis.next_state[j][p];
              if (curMetric > AlphaMetric[nextState][i + 1])
                AlphaMetric[nextState][i + 1] = curMetric;
            end /* for p */
        end /* for j */
    end /* for i */

  /* ------------------------------------------------------------------- */
  /* Beta-Metric (Backward Iteration)                                    */
  /* ------------------------------------------------------------------- */
  BetaMetric = '{ default : -10000000.0 };
  for (j = 0; j < trellis.STATES; j++) 
    oldBetaMetric[j] = -10000000.0; //double.MaxValue;
  oldBetaMetric[0] = 100000.0; /* Termination */
  for (i = numSymbols; i > 0; i -= 1)
    begin
      int tmp, q, b;
      /* precompute the Branch Metric for each output Symbol, based on the LLRs */
      for (q = 0; q < numOutputSymbols; q++)
        begin
          BMVector[q] = 0.0;
          tmp = q;
          for (b = numOutputBits - 1; b >= 0; b--)
            begin
              if (tmp >= (1 << b))
                begin
                  tmp = tmp - (1 << b);
                  BMVector[q] += LLRVector[b][i-1];   /* first bit is MSB */
                end
              else
                begin
                  BMVector[q] -= LLRVector[b][i-1];   /* first bit is MSB */
                end
            end
          /* adjust to max-log metric */
          BMVector[q] = 0.5 * BMVector[q];
        end
      
      /* ------------------ carry out one trellis step ------------------------- */
      for (j = 0; j < trellis.STATES; j++)
        begin                            /* for each state */
          real metricInc, curMetric;
          real outputMetric;
          int bitValue;
          /* for each branch */
          for (p = 0; p < numInputSymbols; p++)
            begin /* for each branch */
              /* ---- Beta ------------- */
              int nextState;
              metricInc = BMVector[trellis.outputs[j][p]];
              nextState = trellis.next_state[j][p];
              curMetric = oldBetaMetric[nextState] + metricInc;
              if ((curMetric > BetaMetric[j]) || (p == 0))
                BetaMetric[j] = curMetric;

              /* ---- output metric of current state ---- */
              outputMetric = curMetric + AlphaMetric[j][i - 1];

              /* ---- a posteriori LLR output calculation ---- */
              bitValue = trellis.outputs[j][p];
              for (b = numOutputBits - 1; b >= 0; b--)
                begin
                  int BitIdx;
                  BitIdx = i * numOutputBits - 1 - b;
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
        end /* for j states */

      /* copy the beta state metric */
      for (q = 0; q < trellis.STATES; q++)
        oldBetaMetric[q] = BetaMetric[q];
      BetaMetricSave[i-1] = BetaMetric;
    end /* for i branches */
 
  llr_0_save = llr_0;
  llr_1_save = llr_1;

  /* Compute a posteriori information [LLRs] */
  for (i = 0; i < NUMBITS; i++)
    llr_d[i] = llr_1[i] - llr_0[i];

  /* output */
  //llr_d /* -- a posteriori output -- */
  for (i = 0; i < BITS_PER_SYMBOL; i++)
    for (j = 0; j < SYMBOLS; j++)
      result[i][j] = llr_d[BITS_PER_SYMBOL * j + i];

  return result;
endfunction

endmodule
