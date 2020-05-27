`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 09:29:24 AM
// Design Name: 
// Module Name: turbo_decode_top
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

module turbo_decode_top
#(BITS = 32, PRECISION = "SINGLE", N = 8, NOUT = 2, TAIL_BITS = 2, HALF_ITER = 1)
(
input clk,
input in_valid,
input [BITS-1:0] single_y,
output logic out_valid,
output logic single_x
);

localparam P = 3;
localparam STATES = 4, NIN = 1, RECURSIVE = 7;
localparam int POLY[NOUT] = '{ 5, 7 };

interleaver_prime_if #(.BITS(BITS), .N(N), .P(P)) interleave();
// Using different interface due to tool bug
// Types for function return in vendor tool changes for first interface without 
// using one with a different name in synthesis for [xx:xx] data[xx] variables
interleaver_prime_if2 #(.BITS(1), .N(N), .P(P)) interleave_result();
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();

logic in_valid_td;
logic [BITS-1:0] y[1 + 2 * (NOUT-1)][N+TAIL_BITS];
logic out_valid_td;
logic x[N];

stream_in_matrix_ping_pong
#(.BITS(BITS), .R(1 + 2 * (NOUT-1)), .C(N+TAIL_BITS))
stream_in_matrix_ping_pong1
(
.clk,
.in_valid,
.a(single_y),
.out_valid(in_valid_td),
.c(y)
);

turbo_decode
#(.BITS(BITS), .PRECISION(PRECISION), .N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
turbo_decode1
(
.clk,
.interleave,
.interleave_result,
.trellis,
.in_valid(in_valid_td),
.y,
.out_valid(out_valid_td),
.x
);

stream_out_vector_ping_pong
#(.BITS(1), .N(N))
stream_out_vector_ping_pong1
(
.clk,
.in_valid(out_valid_td),
.a(x),
.out_valid,
.c(single_x)
);

endmodule
