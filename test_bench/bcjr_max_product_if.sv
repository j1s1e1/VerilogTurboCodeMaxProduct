`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 04:58:28 PM
// Design Name: 
// Module Name: bcjr_max_product_if
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


interface bcjr_max_product_if #(BITS_PER_SYMBOL = 2, SYMBOLS = 10,
    STATES = 2, NIN = 1, NOUT = 2, RECURSIVE = 0, int POLY[NOUT] = '{ default : 0 });

localparam NUMBITS = BITS_PER_SYMBOL * SYMBOLS;
localparam int numInputSymbols = 2 ** NIN;
localparam numInputBits = NIN;
localparam int numOutputSymbols = 2 ** NOUT;
localparam numOutputBits = NOUT;

localparam numSymbols = NUMBITS / numOutputBits;
    
trellis_if  #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT),
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
    
typedef integer unsigned uint;    
typedef real llr_t[BITS_PER_SYMBOL][SYMBOLS];

function llr_t DecodeExt(llr_t data, llr_t extrinsic);
   real scalingFactor;
   llr_t dataWithExtrinsic;
   scalingFactor = 0.7;
   for (int i = 0; i < BITS_PER_SYMBOL; i++)
     for (int j = 0; j < SYMBOLS; j++)
       begin
         dataWithExtrinsic[i][j] = data[i][j];
         if (i == 0)
           dataWithExtrinsic[i][j] += scalingFactor * extrinsic[i][j];
       end
  return Decode(dataWithExtrinsic);
endfunction

function llr_t Decode(llr_t LLRVector);
  llr_t result;
  int i, j;
  uint p;
  real BMVector[numOutputSymbols];

  real AlphaMetric[trellis.STATES][SYMBOLS+1];  // One extra ??
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
  BetaMetric = '{ default : 0 };
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

    end /* for i branches */

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
        
endinterface
