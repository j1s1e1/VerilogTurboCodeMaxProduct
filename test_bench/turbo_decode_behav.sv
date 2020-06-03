`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 04:23:20 PM
// Design Name: 
// Module Name: turbo_decode_behav
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


module turbo_decode_behav
#(N = 64, NOUT = 2, TAIL_BITS = 0, HALF_ITER = 1)
(
input clk,
interface interleave,
interface siso,
trellis_if trellis,
input in_valid,
input real y[1 + 2 * (NOUT-1)][N+TAIL_BITS],
output logic out_valid = 0,
output logic x[N] = '{ default : 0 }
);

localparam BITS_PER_SYMBOL = NOUT;
localparam SYMBOLS = N+TAIL_BITS;

typedef real y_t[1 + 2 * (NOUT-1)][N+TAIL_BITS];
typedef logic x_t[N];
typedef real llr_t[BITS_PER_SYMBOL][SYMBOLS];
typedef real block_t[N];

always @(posedge clk)
  begin
    out_valid <= 0;
    if (in_valid)
      out_valid <= 1;
  end

always @(posedge clk)
  begin
    x <= '{ default : 0};
    if (in_valid)
      x <= TurboDecode(y, HALF_ITER);
  end 
  
function x_t TurboDecode(y_t data, int halfIterations);
  llr_t result;
  x_t result_bits;
  real systematic[N+TAIL_BITS];
  int e1_offset;
  int e2_offset;
  llr_t extrinsic;
  real encoder1_data[NOUT][N+TAIL_BITS];
  real encoder2_data[NOUT][N+TAIL_BITS];
  real systematic_interleaved[N+TAIL_BITS];
  
  e1_offset = 1;
  e2_offset = 1 + NOUT;
  systematic = data[0];
  extrinsic = '{ default : 0 };
  encoder1_data[0] = systematic;
  for (int i = 1; i < NOUT; i++)
    encoder1_data[i] = data[i];
  systematic_interleaved = '{ default : 0 };
  systematic_interleaved[0:N-1] = Forward(systematic[0:N-1]);
  encoder2_data[0] = systematic_interleaved;
  for (int i = 1; i < NOUT; i++)
    encoder2_data[i] = data[NOUT - 1 + i];
  for (int i = 0; i < halfIterations; i++)
    begin
      if (i % 2 == 0)
        begin
            result = siso.DecodeExt(encoder1_data, extrinsic);
            // FIXME Why FLIP here
            extrinsic = Subtract(Flip(result), Scale(extrinsic, 0.7));
            // Need to subtract
            extrinsic = Subtract(extrinsic, Flip(encoder1_data));
            for (int j = 0; j < BITS_PER_SYMBOL; j++)
              extrinsic[j][0:N-1] = Forward(extrinsic[j][0:N-1]);
        end
      else
        begin
            result = siso.DecodeExt(encoder2_data, extrinsic);
            // FIXME Why FLIP here
            extrinsic = Subtract(Flip(result), Scale(extrinsic, 0.7));
            for (int j = 0; j < BITS_PER_SYMBOL; j++)
              result[j][0:N-1] = Reverse(result[j][0:N-1]);
            // Need to subtract
            extrinsic = Subtract(extrinsic, encoder2_data);
            for (int j = 0; j < BITS_PER_SYMBOL; j++)
              extrinsic[j][0:N-1] = Reverse(extrinsic[j][0:N-1]);
        end
    end
  for (int i = 0; i < N; i++)
    result_bits[i] = (result[1][i] <= 0) ? 0 : 1;
  return result_bits;
endfunction

function llr_t Subtract(llr_t a, llr_t b);
  llr_t result;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      result[i][j] = a[i][j] - b[i][j];
  return result;
endfunction

function llr_t Scale(llr_t a, real scale);
  llr_t result;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      result[i][j] = a[i][j] * scale;
  return result;
endfunction

function llr_t Flip(llr_t data);
  llr_t result;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      result[i][j] = data[BITS_PER_SYMBOL - 1 - i][j];
  return result;
endfunction

function block_t Forward(block_t data);
  logic [31:0] inData[N+TAIL_BITS];
  logic [31:0] outData[N+TAIL_BITS];
  for (int i = 0; i < N; i++)
    inData[i] = $shortrealtobits(data[i]);
  outData = interleave.Forward(inData);
  for (int i = 0; i < N; i++)
    Forward[i] = $bitstoshortreal(outData[i]);
endfunction

function block_t Reverse(block_t data);
  logic [31:0] inData[N+TAIL_BITS];
  logic [31:0] outData[N+TAIL_BITS];
  for (int i = 0; i < N; i++)
    inData[i] = $shortrealtobits(data[i]);
  outData = interleave.Reverse(inData);
  for (int i = 0; i < N; i++)
    Reverse[i] = $bitstoshortreal(outData[i]);
endfunction

endmodule
