`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2020 08:00:19 AM
// Design Name: 
// Module Name: turbo_decode_top_tb
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

import channel_tasks_pkg::*;

module turbo_decode_top_tb();

parameter BITS = 32, PRECISION = "SINGLE", N = 8, NOUT = 2, TAIL_BITS = 2, HALF_ITER = 1;

logic clk;
logic in_valid;
logic [BITS-1:0] single_y;
logic [BITS-1:0] y[1 + 2 * (NOUT-1)][N+TAIL_BITS];
logic out_valid;
logic single_x;
logic x[N];

parameter STATES = 4, NIN = 1, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };
parameter P = 3;
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
interleaver_prime_if #(.BITS(1), .N(N), .P(P)) interleave_encode();

logic in_valid_encode;
logic x_encode[N];
logic out_valid_encode;
logic y_encode[1 + 2 * NOUT][N+TAIL_BITS];

typedef logic x_t[N];

function x_t SetX3s();
  x_t result;
  for (int i = 0; i < N; i++)
    result[i] = (((i / 3) % 2) == 0) ? 1 : 0;
  return result;
endfunction

real snrDb = -1000;
real snr = -1000;

task Test(real snrDbIn);
  snrDb = snrDbIn;
  snr = $pow(10, snrDb/10.0);
  in_valid_encode <= 1;
  x_encode <= SetX3s(); //'{ 1, 1, 1, 0, 0, 0, 1, 1, 1, 0 };
  @(posedge clk);
  in_valid_encode <= 0;
  x_encode <= '{ default : 0 };
  @(posedge clk);
  in_valid <= 1;
  for (int i = 0; i < N+TAIL_BITS; i++)
    begin
      y[0][i] <= $shortrealtobits((((y_encode[0][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y[1][i] <= $shortrealtobits((((y_encode[1][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y[2][i] <= $shortrealtobits((((y_encode[3][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
    end
  @(posedge clk);
  in_valid <= 0;
  repeat ((N+TAIL_BITS) * 12) @(posedge clk);
  y <= '{ default : 0 };
endtask

real y1[][];

initial
  begin
    in_valid_encode <= 0;
    x_encode <= '{ default : 0 };
    in_valid <= 0;
    y <= '{ default : 0 };
    repeat (10) @(posedge clk); // make sure syntheszied part has been reset
    @(posedge clk);
    Test(6.0);
    @(posedge clk);
    Test(6.0);
    @(posedge clk);
    Test(5.0);
    @(posedge clk);
    Test(4.0);
    @(posedge clk);
    repeat (50) @(posedge clk);
    $stop;
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
logic in_valid_td;
logic out_valid_td;

stream_out_matrix_ping_pong
#(.BITS(BITS), .R(1 + 2 * (NOUT-1)), .C(N+TAIL_BITS))
stream_out_matrix_ping_pong1
(
.clk,
.in_valid,
.a(y),
.out_valid(in_valid_td),
.c(single_y)
);  

turbo_decode_top
#(.BITS(BITS), .PRECISION(PRECISION), .N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
turbo_decode_top1
(
.clk,
.in_valid(in_valid_td),
.single_y,
.out_valid(out_valid_td),
.single_x
);

stream_in_vector_ping_pong
#(.BITS(1), .N(N))
stream_in_vector_ping_pong1
(
.clk,
.in_valid(out_valid_td),
.a(single_x),
.out_valid,
.c(x)
);

turbo_encode_behav
#(.N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS))
turbo_encode_behav1
(
.clk,
.interleave(interleave_encode),
.trellis,
.in_valid(in_valid_encode),
.x(x_encode),
.out_valid(out_valid_encode),
.y(y_encode)
);

endmodule
