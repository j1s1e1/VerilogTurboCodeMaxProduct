`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 08:33:09 PM
// Design Name: 
// Module Name: turbo_decode
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


module turbo_decode
#(BITS = 16, PRECISION = "HALF", N = 64, NOUT = 2, TAIL_BITS = 0, HALF_ITER = 1)
(
input clk,
interface interleave,
interface interleave_result,
trellis_if trellis,
input in_valid,
input [BITS-1:0] y[1 + 2 * (NOUT-1)][N+TAIL_BITS],
output logic out_valid,
output logic x[N]
);

localparam BITS_PER_SYMBOL = NOUT;
localparam SYMBOLS = N+TAIL_BITS;
localparam ALOGORITHM = "MPA";

typedef logic [BITS-1:0] y_t[1 + 2 * (NOUT-1)][N+TAIL_BITS];
typedef logic x_t[N];
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL][SYMBOLS];
typedef logic [BITS-1:0] block_t[N];

logic in_valid_siso_array[HALF_ITER];
logic [BITS-1:0] encoder1_data[HALF_ITER+1][BITS_PER_SYMBOL][N+TAIL_BITS];
logic [BITS-1:0] encoder2_data[HALF_ITER+1][BITS_PER_SYMBOL][N+TAIL_BITS];
logic [BITS-1:0] extrinsic[HALF_ITER+1][BITS_PER_SYMBOL][SYMBOLS];
logic out_valid_siso_array[HALF_ITER];
logic result[HALF_ITER][N];
logic zeros[N] = '{ default : 0 };

logic [BITS-1:0] systematic[N+TAIL_BITS];
int e1_offset = 1;
int e2_offset = 1 + NOUT;  
logic [BITS-1:0] systematic_interleaved[N+TAIL_BITS];

for (genvar g = 1; g < HALF_ITER; g++)
  assign in_valid_siso_array[g] = out_valid_siso_array[g-1];
  
assign extrinsic[0] = '{ default : 0 };
assign out_valid = (out_valid_siso_array[HALF_ITER-1]) ? 1 : 0;
assign x = (out_valid) ? result[HALF_ITER-1] : zeros;

assign systematic = y[0];  
assign encoder1_data[0][0] = systematic;
for (genvar i = 1; i < NOUT; i++)
  assign encoder1_data[0][i] = y[i];
assign systematic_interleaved[0:N-1] = interleave.Forward(systematic[0:N-1]);
if (TAIL_BITS > 0)
  assign systematic_interleaved[N:N+TAIL_BITS-1] = '{ default : 0 };
assign encoder2_data[0][0] = systematic_interleaved;
for (genvar i = 1; i < NOUT; i++)
  assign encoder2_data[0][i] = y[NOUT - 1 + i];
assign in_valid_siso_array[0] = in_valid;

for (genvar g = 0; g < HALF_ITER; g++)
soft_in_soft_out
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .N(N),
    .SYMBOLS(SYMBOLS), .STATES(trellis.STATES), .HALF_ITER(g[0]), .ALOGORITHM(ALOGORITHM))
soft_in_soft_out_array
(
.clk,
.interleave,
.interleave_result,
.trellis,
.in_valid(in_valid_siso_array[g]),
.encoder1_data_in(encoder1_data[g]),
.encoder2_data_in(encoder2_data[g]),
.extrinsic_in(extrinsic[g]),
.out_valid(out_valid_siso_array[g]),
.encoder1_data_out(encoder1_data[g+1]),
.encoder2_data_out(encoder2_data[g+1]),
.extrinsic_out(extrinsic[g+1]),
.result(result[g])
);

endmodule
