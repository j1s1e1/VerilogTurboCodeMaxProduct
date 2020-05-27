`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 11:13:28 PM
// Design Name: 
// Module Name: soft_in_soft_out_tb
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


module soft_in_soft_out_tb();

parameter BITS = 32, PRECISION = "SINGLE", BITS_PER_SYMBOL = 2, N = 10;
parameter SYMBOLS = 10, HALF_ITER = 0, ALOGORITHM = "MPA";
parameter STATES = 4, NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };

logic clk;
interleaver_prime_if #(.BITS(BITS), .N(N), .P(3)) interleave();
interleaver_prime_if #(.BITS(1), .N(N), .P(3)) interleave_result();
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
    
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL][SYMBOLS];
typedef real llr_real_t[BITS_PER_SYMBOL][SYMBOLS];
    
logic in_valid;
llr_t encoder1_data_in;
llr_t encoder2_data_in;
llr_t extrinsic_in;
logic out_valid;
llr_t encoder1_data_out;
llr_t encoder2_data_out;
llr_t extrinsic_out;
logic result[N];

task Test(llr_real_t ed1, llr_real_t ed2, llr_real_t ex);
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      begin
        encoder1_data_in[i][j] <= $shortrealtobits(ed1[i][j]);
        encoder2_data_in[i][j] <= $shortrealtobits(ed2[i][j]);
        extrinsic_in[i][j] <= $shortrealtobits(ex[i][j]);
      end
  in_valid <= 1;
  @(posedge clk);
  in_valid <= 0;
  encoder1_data_in <= '{ default : 0 };
  encoder2_data_in <= '{ default : 0 };
  extrinsic_in <= '{ default : 0 };
endtask

llr_real_t ed1_1 = '{'{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, '{ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }};
llr_real_t ed2_1 = '{'{ 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 }, '{ 31, 32, 33, 34, 35, 36, 37, 38, 39, 40 }};
llr_real_t ex1 = '{'{ 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.10 }, '{ 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.20 }};

initial
  begin
    in_valid <= 0;
    encoder1_data_in <= '{ default : 0 };
    encoder2_data_in <= '{ default : 0 };
    extrinsic_in <= '{ default : 0 };
    @(posedge clk);
    @(posedge clk);
    Test(ed1_1, ed2_1, ex1);
    @(posedge clk);
    @(posedge clk);
    Test(ed1_1, ed2_1, ex1);
    @(posedge clk);
    repeat (SYMBOLS * (STATES + 1)) @(posedge clk);
    repeat (SYMBOLS * (STATES + 1)) @(posedge clk);
    repeat (10) @(posedge clk);
    $stop;
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end

soft_in_soft_out
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .N(N), .SYMBOLS(SYMBOLS), .HALF_ITER(HALF_ITER), .ALOGORITHM(ALOGORITHM))
soft_in_soft_out1
(
.clk,
.interleave,
.interleave_result,
.trellis,
.in_valid,
.encoder1_data_in,
.encoder2_data_in,
.extrinsic_in,
.out_valid,
.encoder1_data_out,
.encoder2_data_out,
.extrinsic_out,
.result
);

endmodule
