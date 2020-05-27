`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2020 11:11:47 AM
// Design Name: 
// Module Name: trellis_if
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

// WARNING -- 
// File partially updated for recursive functions
// Some unused functions may not have been updated yet !!!!!

interface trellis_if #(STATES = 8, NIN = 1, NOUT = 2, RECURSIVE = 0, int POLY[NOUT] = '{ default : 0 });

parameter int NUM_STATES = SetStates();

function int SetStates();
  SetStates = STATES;
endfunction

parameter STATE_BITS = $clog2(STATES);
parameter INPUT_BITS = NIN;
parameter INPUT_SYMBOLS = 2**NIN;
parameter OUTPUT_BITS = NOUT;
parameter OUTPUT_SYMBOLS = 2**NOUT;

typedef logic [STATE_BITS-1:0] state_t;
typedef logic [STATE_BITS-1:0] next_state_t[STATES][INPUT_SYMBOLS];

parameter next_state_t next_state = CalcNextStates();

typedef logic [STATE_BITS-1:0] prev_state_t[STATES][INPUT_SYMBOLS];

parameter prev_state_t prev_state = CalcPrevStates();

// Output for each input
typedef logic output_t[STATES][NOUT][2];

parameter output_t out_bits = CalcOutput();

typedef logic [NOUT-1:0] outputs_t[STATES][2**NIN];

// another version to match matlab model
parameter outputs_t outputs = CalcOutputs();

typedef logic input_index_t[STATES][2];

// Input value that causes state to transition to state
parameter input_index_t input_index = CalcInputIndexes();

// Outputs for each input
typedef logic trellis_out_t[STATES][2][NOUT];

parameter trellis_out_t trellis_out = CalcTrellisOut();

// Branch Metric from this state to next state
typedef logic [NOUT-1:0]  branch_metric_selection_t[STATES][2];

parameter branch_metric_selection_t branch_metric_selection = CalcBranchMetricSelections();

// Branch Metric from previous state to this state
typedef logic [NOUT-1:0]  previous_state_bms_t[STATES][2];

parameter previous_state_bms_t previous_state_bms = CalcPreviousStateBMS();

typedef logic [NIN-1:0]  llr_bms_t[STATES][OUTPUT_BITS][INPUT_SYMBOLS/2];

parameter llr_bms_t llr_0_bms = CalcLLR0Bms();

typedef logic [NIN-1:0]  state_llr_bms_t[OUTPUT_BITS][INPUT_SYMBOLS/2];

parameter llr_bms_t llr_1_bms = CalcLLR1Bms();

function state_t SingleNextState(state_t state, logic input_bit);
  logic input_bit_with_recursive;
  input_bit_with_recursive = input_bit;
  if (RECURSIVE != 0)
    input_bit_with_recursive = ^({input_bit,state} & RECURSIVE);
  SingleNextState = {input_bit_with_recursive, state[STATE_BITS-1:1]};
endfunction

function next_state_t CalcNextStates();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < 2; j++)
      CalcNextStates[i][j] = SingleNextState(i, j);
endfunction

function state_t SinglePrevState(state_t state, int prev_state_index);
  int count;
  count = -1;
  for (int i = 0; i < STATES; i++)
    begin
      for (int j = 0; j < 2; j++)
        if (SingleNextState(i, j) == state)
          count++;
      if (count == prev_state_index)
        return i;
    end
endfunction

// Previous states are in order from lowest previous state to highest previous state
function next_state_t CalcPrevStates();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < 2; j++)
      CalcPrevStates[i][j] = SinglePrevState(i, j);
endfunction

function logic SingleOutput(state_t state, logic output_number,  logic input_bit);
  logic input_bit_with_recursive;
  input_bit_with_recursive = input_bit;
  if (RECURSIVE != 0)
    input_bit_with_recursive = ^({input_bit,state} & RECURSIVE);
  return ^({input_bit_with_recursive,state} & POLY[output_number]);
endfunction

function output_t CalcOutput();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < NOUT; j++)
      for (int k = 0; k < 2; k++)
        CalcOutput[i][j][k] = SingleOutput(i, j, k);
endfunction

//  Feedforward for now
function input_index_t CalcInputIndexes();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < 2; j++)
      CalcInputIndexes[i][j] = i[0];
endfunction

function trellis_out_t CalcTrellisOut();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < 2; j++)
      for (int k = 0; k < NOUT; k++)
        CalcTrellisOut[i][j][k] = SingleOutput(i, k, j);    // Note k and j switched in calc
endfunction

typedef logic [NOUT-1:0] single_outputs_t;

function single_outputs_t SingleOutputs(state_t state, int input_symbol);
  SingleOutputs = 0;
  for (int k = 0; k < NOUT; k++)
    SingleOutputs = 2 * SingleOutputs + SingleOutput(state, k, input_symbol);
endfunction

function outputs_t CalcOutputs();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < 2; j++)
      CalcOutputs[i][j] = SingleOutputs(i, j);
endfunction

function logic [NOUT-1:0] SingleBranchMetricSelection(logic [STATE_BITS-1:0] state, logic input_bit);
  SingleBranchMetricSelection = 0;
  for (int i = 0; i < NOUT; i++)
    SingleBranchMetricSelection |= ^({state,input_bit} & POLY[i]) << i;
endfunction

function branch_metric_selection_t CalcBranchMetricSelections();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < 2; j++)
      CalcBranchMetricSelections[i][j] = SingleBranchMetricSelection(i, j);
endfunction

function logic [NIN-1:0] SinglePreviousStateInputBits(state_t previous_state, state_t current_state);
  for (int i = 0; i < 2**NIN; i++)
    if (SingleNextState(previous_state, i) == current_state)
      SinglePreviousStateInputBits = i;
endfunction

function logic [NOUT-1:0] SinglePreviousStateBMS(logic [STATE_BITS-1:0] state, logic prev_state_index);
  state_t previous_state;
  logic [NIN-1:0] input_bits;
  previous_state = SinglePrevState(state, prev_state_index);
  input_bits = SinglePreviousStateInputBits(previous_state, state);
  SinglePreviousStateBMS = SingleOutputs(previous_state, input_bits);
endfunction

function previous_state_bms_t CalcPreviousStateBMS();
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < 2; j++)
      CalcPreviousStateBMS[i][j] = SinglePreviousStateBMS(i, j);
endfunction

parameter state_llr_bms_t llr_bms_test = CalcStateLLR2(2, 1);

function state_llr_bms_t CalcStateLLR2(state_t state, logic bit_value);
  logic [NOUT-1:0] output_symbol;
  int output_bit_counts[OUTPUT_BITS];
  output_bit_counts = '{ default : 0 };
  for (int i = 0; i < 2; i++)
    CalcStateLLR2[i][0] = i;
endfunction

function state_llr_bms_t CalcStateLLR(state_t state, logic bit_value);
  logic [NOUT-1:0] output_symbol;
  int output_bit_counts[OUTPUT_BITS];
  //CalcStateLLR = '{ default : 0 };    This seems to break the function
  output_bit_counts = '{ default : 0 };
  for (int i = 0; i < INPUT_SYMBOLS; i++)
    begin
      output_symbol = SingleOutputs(state, i);
      for (int j = 0; j < OUTPUT_BITS; j++)
        if (output_symbol[OUTPUT_BITS - 1 - j] == bit_value)
          begin
            CalcStateLLR[j][output_bit_counts[j]] = i;
            output_bit_counts[j]++;
          end
    end
endfunction

function llr_bms_t CalcLLR0Bms();
  for (int i = 0; i < STATES; i++)
    CalcLLR0Bms[i] = CalcStateLLR(i, 0);
endfunction

function llr_bms_t CalcLLR1Bms();
  for (int i = 0; i < STATES; i++)
    CalcLLR1Bms[i] = CalcStateLLR(i, 1);
endfunction

// Test Bench Functions

typedef logic tail_bits_t[NOUT][STATE_BITS];

function void Encode(logic data_in[], output logic data_out[][], input int tail_bits = 0);
  logic [STATE_BITS-1:0] current_state;
  logic data_temp[][];
  tail_bits_t tailbits;
  data_temp = new[data_in.size() + tail_bits];
  current_state = 0;
  for (int i = 0; i < data_in.size(); i++)
    begin
      data_temp[i] = new[NOUT];
      for (int j = 0; j < NOUT; j++)
        data_temp[i][j] = SingleOutput(current_state, j,  data_in[i]);
      current_state = next_state[current_state][data_in[i]];
    end
  tailbits = TailBits(current_state);
  data_out = new[NOUT];
  for (int i = 0; i < NOUT; i++)
    begin
      data_out[i] = new[data_in.size() + tail_bits];
      for (int j = 0; j < data_in.size(); j++)
        data_out[i][j] = data_temp[j][i];
        
      for (int j = 0; j < tail_bits; j++)
        data_out[i][data_in.size() + j] = tailbits[i][j];
    end
endfunction

function void BranchMetrics(real data[], output real branch_metrics[]);
  branch_metrics = new[2**NOUT];
  for (int i = 0; i < 2**NOUT; i++)
    begin
      branch_metrics[i] = 0;
      for (int j = 0; j < NOUT; j++)
        if ((i >> j) % 2 == 0)
          branch_metrics[i] += (data[j] - -1.0)**2;
        else 
          branch_metrics[i] += (data[j] - 1.0)**2;
    end
endfunction

function tail_bits_t TailBits(int state);
  tail_bits_t result;
  int outState;
  int test;
  outState = -1;
  test = 0;
  while (outState != 0)
    begin
      outState = state;
      for (int i = 0; i < STATE_BITS; i++)
        begin
          result[0][i] = SingleOutput(outState, 0, (test >> i) % 2);
          result[1][i] = SingleOutput(outState, 1, (test >> i) % 2);
          outState = next_state[outState][(test >> i) % 2];
        end
      test = test + 1;
    end
  return result;
endfunction

endinterface
