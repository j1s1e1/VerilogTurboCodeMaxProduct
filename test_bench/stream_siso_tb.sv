`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 04:44:30 PM
// Design Name: 
// Module Name: stream_siso_tb
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


module stream_siso_tb();

parameter BITS = 32, PRECISION = "SINGLE", BITS_PER_SYMBOL = 2, N = 29;
parameter SYMBOLS = N, HALF_ITER = 0, ALOGORITHM = "MPA";
parameter STATES = 4, NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };
parameter TAIL_BITS = 0;

logic clk;
interleaver_prime_if #(.BITS(BITS), .N(N), .P(3), .TAIL_BITS(TAIL_BITS)) interleave();
interleaver_prime_if #(.BITS(1), .N(N), .P(3), .TAIL_BITS(TAIL_BITS)) interleave_result();
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
    
typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL];
typedef real llr_real_t[BITS_PER_SYMBOL][SYMBOLS];
typedef logic [BITS-1:0] llr_no_stream_t[BITS_PER_SYMBOL][SYMBOLS];
    
logic in_valid;
llr_t encoder1_data_in;
llr_t encoder2_data_in;
llr_t extrinsic_in;
logic out_valid;
llr_t encoder1_data_out;
llr_t encoder2_data_out;
llr_t extrinsic_out;
logic result;

int result_errors = 0;
logic save_result_stream[N] = '{ default : 0 };

always @(posedge clk)
  begin
    save_result_stream <= save_result_stream;
    if (out_valid)
      save_result_stream <= {save_result_stream[1:N-1],result};
  end

int extrinsic_errors = 0;
llr_no_stream_t save_extrinsic_out_stream = '{ default : 0 };

always @(posedge clk)
  begin
    save_extrinsic_out_stream <= save_extrinsic_out_stream;
    if (out_valid)
      for (int i = 0; i < BITS_PER_SYMBOL; i++)
        save_extrinsic_out_stream[i] <= {save_extrinsic_out_stream[i][1:SYMBOLS-1],extrinsic_out[i]};
  end

logic in_valid_no_stream;
llr_no_stream_t encoder1_data_in_no_stream;
llr_no_stream_t encoder2_data_in_no_stream;
llr_no_stream_t extrinsic_in_no_stream;
logic out_valid_no_stream;
llr_no_stream_t encoder1_data_out_no_stream;
llr_no_stream_t encoder2_data_out_no_stream;
llr_no_stream_t extrinsic_out_no_stream;
logic result_no_stream[N];

function void CompareResults();
  int differences;
  differences = 0;
  for (int i = 0; i < N; i++)
    if (result_no_stream[i] != save_result_stream[i])
      differences++;
  result_errors = differences;
endfunction

function void CompareExtrinsic();
  int differences;
  differences = 0;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
    if (extrinsic_out_no_stream[i][j] != save_extrinsic_out_stream[i][j])
      differences++;
  extrinsic_errors = differences;
endfunction

function CompareOutputs();
  CompareResults();
  CompareExtrinsic();
endfunction

always @(posedge clk)
  begin
    if (out_valid_no_stream)
      CompareOutputs();
  end

task TestStream(llr_real_t ed1, llr_real_t ed2, llr_real_t ex);
  in_valid <= 1;
  for (int i = 0; i < SYMBOLS; i++)
    begin
      for (int j = 0; j < BITS_PER_SYMBOL; j++)
        begin
          encoder1_data_in[j] <= $shortrealtobits(ed1[j][i]);
          encoder2_data_in[j] <= $shortrealtobits(ed2[j][i]);
          extrinsic_in[j] <= $shortrealtobits(ex[j][i]);
        end
        @(posedge clk);
      end
  in_valid <= 0;
  encoder1_data_in <= '{ default : 0 };
  encoder2_data_in <= '{ default : 0 };
  extrinsic_in <= '{ default : 0 };
endtask

task TestNoStream(llr_real_t ed1, llr_real_t ed2, llr_real_t ex);
  in_valid_no_stream <= 1;
  for (int i = 0; i < SYMBOLS; i++)
    begin
      for (int j = 0; j < BITS_PER_SYMBOL; j++)
        begin
          encoder1_data_in_no_stream[j][i] <= $shortrealtobits(ed1[j][i]);
          encoder2_data_in_no_stream[j][i] <= $shortrealtobits(ed2[j][i]);
          extrinsic_in_no_stream[j][i] <= $shortrealtobits(ex[j][i]);
        end
      end
  @(posedge clk);
  in_valid_no_stream <= 0;
  while (out_valid_no_stream != 1) @(posedge clk);
  encoder1_data_in_no_stream <= '{ default : 0 };
  encoder2_data_in_no_stream <= '{ default : 0 };
  extrinsic_in_no_stream <= '{ default : 0 };
endtask

function llr_real_t RandomLLR();
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      RandomLLR[i][j] = $random()/(2.0**32) * 6;
endfunction

task Test();
  llr_real_t ed1;
  llr_real_t ed2;
  llr_real_t ex;
  ed1 = RandomLLR();
  ed2 = RandomLLR();
  ex = RandomLLR();
  fork
    TestStream(ed1, ed2, ex);
    TestNoStream(ed1, ed2, ex);
  join
endtask

//llr_real_t ed1_1 = '{'{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, '{ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }};
//llr_real_t ed2_1 = '{'{ 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 }, '{ 31, 32, 33, 34, 35, 36, 37, 38, 39, 40 }};
//llr_real_t ex1 = '{'{ 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.10 }, '{ 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.20 }};

initial
  begin
    in_valid <= 0;
    encoder1_data_in <= '{ default : 0 };
    encoder2_data_in <= '{ default : 0 };
    extrinsic_in <= '{ default : 0 };
    in_valid_no_stream <= 0;
    encoder1_data_in_no_stream <= '{ default : 0 };
    encoder2_data_in_no_stream <= '{ default : 0 };
    extrinsic_in_no_stream <= '{ default : 0 };
    @(posedge clk);
    @(posedge clk);
    Test();
    Test();
    repeat(12) @(posedge clk);
    Test();
    repeat(12) @(posedge clk);
    Test();
    repeat(13) @(posedge clk);
    Test();
    repeat(10) @(posedge clk);
    @(posedge clk);
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

stream_siso
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .N(N), .SYMBOLS(SYMBOLS), .HALF_ITER(HALF_ITER), .ALOGORITHM(ALOGORITHM), .STATES(STATES))
stream_siso1
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

soft_in_soft_out
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .N(N), .SYMBOLS(SYMBOLS), .STATES(STATES), .HALF_ITER(HALF_ITER), .ALOGORITHM(ALOGORITHM))
soft_in_soft_out1
(
.clk,
.interleave,
.interleave_result,
.trellis,
.in_valid(in_valid_no_stream),
.encoder1_data_in(encoder1_data_in_no_stream),
.encoder2_data_in(encoder2_data_in_no_stream),
.extrinsic_in(extrinsic_in_no_stream),
.out_valid(out_valid_no_stream),
.encoder1_data_out(encoder1_data_out_no_stream),
.encoder2_data_out(encoder2_data_out_no_stream),
.extrinsic_out(extrinsic_out_no_stream),
.result(result_no_stream)
);

endmodule
