`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2020 05:17:03 PM
// Design Name: 
// Module Name: stream_turbo_decode_top
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


module stream_turbo_decode_top
#(BITS = 32, PRECISION = "SINGLE", N = 8, NOUT = 2, TAIL_BITS = 2, HALF_ITER = 3)
(
input clk,
input in_valid,
input [BITS-1:0] y0,
input [BITS-1:0] y1,
input [BITS-1:0] y2,
output logic out_valid,
output logic x
);

localparam P = 3;
localparam STATES = 4, NIN = 1, RECURSIVE = 7;
localparam int POLY[NOUT] = '{ 5, 7 };

interleaver_prime_if #(.BITS(BITS), .N(N), .P(P), .TAIL_BITS(TAIL_BITS)) interleave();
// Using different interface due to tool bug
// Types for function return in vendor tool changes for first interface without 
// using one with a different name in synthesis for [xx:xx] data[xx] variables
interleaver_prime_if2 #(.BITS(1), .N(N), .P(P), .TAIL_BITS(TAIL_BITS)) interleave_result();
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();

// Set up for specific test for now
logic [BITS-1:0] y[1 + 2 * (NOUT-1)];

assign y = '{ y0, y1, y2 };

stream_turbo_decode
#(.BITS(BITS), .PRECISION(PRECISION), .N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
stream_turbo_decode1
(
.clk,
.interleave,
.interleave_result,
.trellis,
.in_valid,
.y,
.out_valid,
.x
);

endmodule
