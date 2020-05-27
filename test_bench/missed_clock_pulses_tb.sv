`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 10:08:28 PM
// Design Name: 
// Module Name: missed_clock_pulses_tb
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

module missed_clock_pulses_tb();


parameter BITS = 32, PRECISION = "SINGLE";
parameter N = 17, NOUT = 2, TAIL_BITS = 2, HALF_ITER = 3;
parameter STATES = 4, NIN = 1, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };
parameter BITS_PER_SYMBOL = NOUT, SYMBOLS = N + TAIL_BITS;

parameter P = 3;

logic clk;
interleaver_prime_if #(.BITS(BITS), .N(N), .P(P)) interleave();
bcjr_max_product_if #(.BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS),
    .STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) siso();
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
logic in_valid;
logic [BITS-1:0] y[1 + 2 * (NOUT-1)][N+TAIL_BITS];
logic out_valid;
logic x[N];

int errors = -1;
int sysematic_bit_errors = -1;

always @(posedge clk)
  begin
    errors <= errors;
    if (out_valid)
      errors <= Errors(SetX3s(), x);
  end

logic systematic_bits[N];
always @(posedge clk)
  begin
    sysematic_bit_errors <= sysematic_bit_errors;
    if (in_valid)
      begin
        for (int i = 0; i < N; i++)
          systematic_bits[i] = (y[0][i][BITS-1] == 0) ? 1 : 0;
        sysematic_bit_errors <= Errors(SetX3s(), systematic_bits);
      end
  end
  

typedef logic x_t[N];

function x_t SetX3s();
  x_t result;
  for (int i = 0; i < N; i++)
    result[i] = (((i / 3) % 2) == 0) ? 1 : 0;
  return result;
endfunction

interleaver_prime_if #(.BITS(1), .N(N), .P(P)) interleave_encode();
logic in_valid_encode;
logic x_encode[N];
logic out_valid_encode;
logic y_encode[1 + 2 * NOUT][N+TAIL_BITS];

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
  y <= '{ default : 0 };
  repeat(N*5) @(posedge clk);
endtask

real y1[1 + 2 * (NOUT-1)][N+TAIL_BITS];

task RepeatTest(real snr, int count);
  for (int i = 0; i < count; i++)
    Test(snr);
endtask

initial
  begin
    in_valid_encode = 0;
    x_encode = '{ default : 0 };
    in_valid = 0;
    y = '{ default : 0 };
    @(posedge clk);
    RepeatTest(4.0, 5);
    RepeatTest(2.0, 5);
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
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
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

turbo_decode
#(.BITS(BITS), .PRECISION(PRECISION), .N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
turbo_decode1
(
.clk,
.interleave,
.interleave_result(interleave_encode),
.trellis,
.in_valid,
.y,
.out_valid,
.x
);

endmodule
