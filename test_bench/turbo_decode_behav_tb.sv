`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 05:30:14 PM
// Design Name: 
// Module Name: turbo_decode_behav_tb
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

module turbo_decode_behav_tb();

parameter N = 10, NOUT = 2, TAIL_BITS = 2, HALF_ITER = 3;
parameter STATES = 4, NIN = 1, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };  // Not including systematic here
parameter BITS_PER_SYMBOL = NOUT, SYMBOLS = N + TAIL_BITS;
parameter type DATA_TYPE = logic [31:0];

logic clk;
interleaver_prime_if #(.DATA_TYPE(DATA_TYPE), .N(N), .P(3)) interleave();
bcjr_max_product_if #(.BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS),
    .STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) siso();
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
logic in_valid;
real y[1 + 2 * (NOUT-1)][N+TAIL_BITS];
logic out_valid;
logic x[N];

interleaver_prime_if #(.DATA_TYPE(logic [0:0]), .N(N), .P(3)) interleave_encode();
logic in_valid_encode;
logic x_encode[N];
logic out_valid_encode;
logic y_encode[1 + 2 * NOUT][N+TAIL_BITS];

task Test(real snrDb);
  real snr;
  snr = $pow(10, snrDb/10.0);
  in_valid_encode <= 1;
  x_encode <= '{ 1, 1, 1, 0, 0, 0, 1, 1, 1, 0 };
  @(posedge clk);
  in_valid_encode <= 0;
  x_encode <= '{ default : 0 };
  @(posedge clk);
  in_valid <= 1;
  for (int i = 0; i < N+TAIL_BITS; i++)
    begin
      y[0][i] <= ((y_encode[0][i] == 1) ? 1 : -1) + RandStdNormal() / snr;
      y[1][i] <= ((y_encode[1][i] == 1) ? 1 : -1) + RandStdNormal() / snr;;
      y[2][i] <= ((y_encode[3][i] == 1) ? 1 : -1) + RandStdNormal() / snr;;
    end
  @(posedge clk);
  in_valid <= 0;
  y <= '{ default : 0 };
endtask

real y1[1 + 2 * (NOUT-1)][N+TAIL_BITS];

initial
  begin
    in_valid_encode <= 0;
    x_encode <= '{ default : 0 };
    in_valid <= 0;
    y <= '{ default : 0 };
    @(posedge clk);
    Test(0.0);
    @(posedge clk);
    Test(-0.5);
    @(posedge clk);
    Test(-1.0);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
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

turbo_decode_behav
#(.N(N), .NOUT(NOUT), .TAIL_BITS(TAIL_BITS), .HALF_ITER(HALF_ITER))
turbo_decode_behav1
(
.clk,
.interleave,
.siso,
.trellis,
.in_valid,
.y,
.out_valid,
.x
);

endmodule
