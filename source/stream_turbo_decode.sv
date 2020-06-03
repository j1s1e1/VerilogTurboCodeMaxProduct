`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2020 09:29:05 AM
// Design Name: 
// Module Name: stream_turbo_decode
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


module stream_turbo_decode
#(BITS = 16, PRECISION = "HALF", N = 64, NOUT = 2, TAIL_BITS = 0, HALF_ITER = 1)
(
input clk,
interface interleave,
interface interleave_result,
trellis_if trellis,
input in_valid,
input [BITS-1:0] y[1 + 2 * (NOUT-1)],
output logic out_valid,
output logic x
);


localparam BITS_PER_SYMBOL = NOUT;
localparam SYMBOLS = N+TAIL_BITS;
localparam ALOGORITHM = "MPA";

typedef logic [BITS-1:0] y_t[1 + 2 * (NOUT-1)];
typedef logic x_t[N];
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL];
typedef logic [BITS-1:0] block_t;

logic in_valid_siso_array[HALF_ITER];
logic [BITS-1:0] encoder1_data[HALF_ITER+1][BITS_PER_SYMBOL];
logic [BITS-1:0] encoder2_data[HALF_ITER+1][BITS_PER_SYMBOL];
logic [BITS-1:0] extrinsic[HALF_ITER+1][BITS_PER_SYMBOL];
logic out_valid_siso_array[HALF_ITER];
logic result[HALF_ITER];

logic [BITS-1:0] systematic;
int e1_offset = 1;
int e2_offset = 1 + NOUT;  
logic [BITS-1:0] y_d[1 + 2 * (NOUT-1)];
logic [BITS-1:0] systematic_interleaved;
logic out_valid_systematic_interleave;

logic [$clog2(SYMBOLS):0] output_bit_count = 0;

always @(posedge clk)
  begin
    output_bit_count <= output_bit_count;
    if (out_valid_siso_array[HALF_ITER-1])
      if (output_bit_count < SYMBOLS - 1)
        output_bit_count <= output_bit_count + 1;
      else
        output_bit_count <= 0;
  end

assign in_valid_siso_array[0] = out_valid_systematic_interleave;
for (genvar g = 1; g < HALF_ITER; g++)
  assign in_valid_siso_array[g] = out_valid_siso_array[g-1];
  
assign extrinsic[0] = '{ default : 0 };
assign out_valid = (out_valid_siso_array[HALF_ITER-1] && (output_bit_count < N)) ? 1 : 0;
assign x = (out_valid) ? result[HALF_ITER-1] : 0;

stream_interleaver
#(.BITS(BITS), .N(N+TAIL_BITS), .DIR("F"))
stream_interleaver_systematic
(
.clk,
.interleave,
.in_valid,
.data_in(y[0]),
.out_valid(out_valid_systematic_interleave),
.data_out(systematic_interleaved)
);

delay_v #(.DELAY(SYMBOLS+1), .WIDTH(BITS), .LENGTH(1 + 2 * (NOUT-1)))
delay_v_encoder1_data
(
.rstn(1'b1),
.clk(clk),
.a(y),
.c(y_d)
); 

assign systematic = y_d[0];

assign encoder1_data[0][0] = systematic;
for (genvar i = 1; i < NOUT; i++)
  assign encoder1_data[0][i] = y_d[i];

assign encoder2_data[0][0] = systematic_interleaved;
for (genvar i = 1; i < NOUT; i++)
  assign encoder2_data[0][i] = y_d[NOUT - 1 + i];

for (genvar g = 0; g < HALF_ITER; g++)
stream_siso
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .N(N),
    .SYMBOLS(SYMBOLS), .STATES(trellis.STATES), .HALF_ITER(g[0]), .ALOGORITHM(ALOGORITHM))
stream_siso_array
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
