`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2020 09:48:16 AM
// Design Name: 
// Module Name: stream_turbo_decode_tb
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

module stream_turbo_decode_tb();

parameter BITS = 32, PRECISION = "SINGLE";
parameter N = 29, NOUT = 2, TAIL_BITS = 2, HALF_ITER = 3;
parameter STATES = 4, NIN = 1, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };
parameter BITS_PER_SYMBOL = NOUT, SYMBOLS = N + TAIL_BITS;

parameter P = 3;

logic clk;
interleaver_prime_if #(.BITS(BITS), .N(N), .P(P), .TAIL_BITS(TAIL_BITS)) interleave();
bcjr_max_product_if #(.BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS),
    .STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) siso();
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
logic in_valid;
logic [BITS-1:0] y[1 + 2 * (NOUT-1)];
logic out_valid;
logic x;

logic in_valid_no_stream;
logic [BITS-1:0] y_no_stream[1 + 2 * (NOUT-1)][SYMBOLS];
logic out_valid_no_stream;
logic x_no_stream[N];

logic [BITS-1:0] y_shared[1 + 2 * (NOUT-1)][SYMBOLS] = '{ default : 0 };

int errors = -1;

/*
always @(posedge clk)
  begin
    errors <= errors;
    if (out_valid)
      errors <= Errors(SetX3s(), x);
  end
*/

typedef logic x_t[N];

function x_t SetX3s();
  x_t result;
  for (int i = 0; i < N; i++)
    result[i] = (((i / 3) % 2) == 0) ? 1 : 0;
  return result;
endfunction

interleaver_prime_if #(.BITS(1), .N(N), .P(P)) interleave_encode();
interleaver_prime_if #(.BITS(1), .N(N), .P(P), .TAIL_BITS(TAIL_BITS)) interleave_result();
logic in_valid_encode;
logic x_encode[N];
logic out_valid_encode;
logic y_encode[1 + 2 * NOUT][N+TAIL_BITS];
logic y_encode_copy[1 + 2 * NOUT][N+TAIL_BITS];

logic in_valid_behav;
real y_behav[1 + 2 * (NOUT-1)][N+TAIL_BITS];
logic out_valid_behav;
logic x_behav[N];

task TestBehav(real snr);
  in_valid_behav <= 1;
  for (int i = 0; i < N+TAIL_BITS; i++)
    begin
      y_behav[0][i] <= ((y_encode_copy[0][i] == 1) ? 1 : -1) + RandStdNormal() / snr;
      y_behav[1][i] <= ((y_encode_copy[1][i] == 1) ? 1 : -1) + RandStdNormal() / snr;;
      y_behav[2][i] <= ((y_encode_copy[3][i] == 1) ? 1 : -1) + RandStdNormal() / snr;;
    end
  @(posedge clk);
  in_valid_behav <= 0;
  y_behav <= '{ default : 0 };
endtask

real snr;

function void CalcYShared(real snr);
  for (int i = 0; i < N+TAIL_BITS; i++)
    begin
      y_shared[0][i] = $shortrealtobits((((y_encode_copy[0][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y_shared[1][i] = $shortrealtobits((((y_encode_copy[1][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y_shared[2][i] = $shortrealtobits((((y_encode_copy[3][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
    end
endfunction

task TestNoStream();
  in_valid_no_stream <= 1;
  for (int i = 0; i < N+TAIL_BITS; i++)
    begin
      y_no_stream[0][i] <= y_shared[0][i]; // $shortrealtobits((((y_encode_copy[0][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y_no_stream[1][i] <= y_shared[1][i]; // $shortrealtobits((((y_encode_copy[1][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y_no_stream[2][i] <= y_shared[2][i]; // $shortrealtobits((((y_encode_copy[3][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
    end
  @(posedge clk);
  in_valid_no_stream <= 0;
  y_no_stream <= '{ default : 0 };
endtask

task TestStream();
 in_valid <= 1;
  for (int i = 0; i < N+TAIL_BITS; i++)
    begin
      y[0] <= y_shared[0][i]; // $shortrealtobits((((y_encode_copy[0][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y[1] <= y_shared[1][i]; // $shortrealtobits((((y_encode_copy[1][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      y[2] <= y_shared[2][i]; // $shortrealtobits((((y_encode_copy[3][i] == 1) ? 1 : -1) + (RandStdNormal() / $sqrt(snr))) * 2.0 * snr);
      /* Test without tail bit info
      if (i >= N)
        begin
          y[0] <= 0;
          y[1] <= 0;
          y[2] <= 0;
        end
      */
      /* Test without noise
      y[0] <= $shortrealtobits((((y_encode_copy[0][i] == 1) ? 1 : -1)) * 2.0 * snr);
      y[1] <= $shortrealtobits((((y_encode_copy[1][i] == 1) ? 1 : -1)) * 2.0 * snr);
      y[2] <= $shortrealtobits((((y_encode_copy[3][i] == 1) ? 1 : -1)) * 2.0 * snr);
      */
      @(posedge clk);
    end
  in_valid <= 0;
  y <= '{ default : 0 };
endtask
  
task Test(real snrDb);
  snr = $pow(10, snrDb/10.0);
  in_valid_encode <= 1;
  x_encode <= SetX3s(); //'{ 1, 1, 1, 0, 0, 0, 1, 1, 1, 0 };
  @(posedge clk);
  in_valid_encode <= 0;
  x_encode <= '{ default : 0 };
  @(posedge clk);
  y_encode_copy = y_encode;
  //TestBehav(snr);
  CalcYShared(snr);
  fork
    TestStream();
    TestNoStream();
  join
endtask

task RepeatWithSameData(real snrDb);
  snr = $pow(10, snrDb/10.0);
  CalcYShared(snr);
  fork
    TestStream();
    TestNoStream();
  join
endtask

real y1[1 + 2 * (NOUT-1)][N+TAIL_BITS];

task RepeatTest(real snr, int count);
  for (int i = 0; i < count; i++)
    Test(snr);
endtask

initial
  begin
    fork
      MainTask();
      ClockTask();
    join
  end

task MainTask();
    in_valid_encode = 0;
    x_encode = '{ default : 0 };
    in_valid = 0;
    y = '{ default : 0 };
    in_valid_behav = 0;
    y_behav = '{ default : 0 };
    in_valid_no_stream = 0;
    y_no_stream <= '{ default : 0 };
    @(posedge clk);
    //RepeatTest(6.0, 10);
    Test(6.0);
    repeat (50) @(posedge clk);
    Test(6.0);
    repeat (50) @(posedge clk);
    Test(6.0);
    RepeatWithSameData(6.0);
    RepeatWithSameData(6.0);
    repeat (50) @(posedge clk);
    Test(2.0);
    repeat (50) @(posedge clk);
    Test(1.0);
    repeat (50) @(posedge clk);
    Test(0.0);
    repeat (50) @(posedge clk);
    Test(-0.25);
    repeat (50) @(posedge clk);
    Test(-0.5);
    repeat (50) @(posedge clk);
    Test(-1.0);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    repeat (200) @(posedge clk);
    $stop;
endtask

task ClockTask();
    clk = 0;
    forever #10 clk = ~clk;
endtask
  
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

stream_turbo_decode
#(.BITS(BITS), .PRECISION(PRECISION), .N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
stream_turbo_decode1
(
.clk,
.interleave,
.interleave_result(interleave_result),
.trellis,
.in_valid,
.y,
.out_valid,
.x
);

turbo_decode
#(.BITS(BITS), .PRECISION(PRECISION), .N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
turbo_decode1
(
.clk,
.interleave,
.interleave_result(interleave_encode),
.trellis,
.in_valid(in_valid_no_stream),
.y(y_no_stream),
.out_valid(out_valid_no_stream),
.x(x_no_stream)
);

turbo_decode_behav
#(.N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
turbo_decode_behav1
(
.clk,
.interleave,
.siso,
.trellis,
.in_valid(in_valid_behav),
.y(y_behav),
.out_valid(out_valid_behav),
.x(x_behav)
);

int max_product_delay_count = 0;

module_timing_check module_timing_check1
(
.clk,
.in_valid(stream_turbo_decode_tb.stream_turbo_decode1.genblk4[0].stream_siso_array.genblk2.stream_bcjr_max_product1.in_valid),
.out_valid(stream_turbo_decode_tb.stream_turbo_decode1.genblk4[0].stream_siso_array.genblk2.stream_bcjr_max_product1.out_valid),
.count(max_product_delay_count)
);

endmodule
