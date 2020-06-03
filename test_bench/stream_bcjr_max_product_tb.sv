`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 09:18:48 AM
// Design Name: 
// Module Name: stream_bcjr_max_product_tb
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


module stream_bcjr_max_product_tb();

parameter BITS = 32, PRECISION = "SINGLE";
parameter BITS_PER_SYMBOL = 2, SYMBOLS = 17;
parameter STATES = 4, NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
real LLRVector[BITS_PER_SYMBOL][SYMBOLS];
real LLR_D[BITS_PER_SYMBOL][SYMBOLS];

logic clk;
logic in_valid;
logic out_valid;

logic in_valid_stream;
logic [BITS-1:0] LLRVector_stream[BITS_PER_SYMBOL];
logic out_valid_stream;
logic [BITS-1:0] LLR_D_stream[BITS_PER_SYMBOL];
logic [BITS-1:0] SavedLLR_D_stream[BITS_PER_SYMBOL][SYMBOLS] = '{ default : 0 };

always @(posedge clk)
  begin
    SavedLLR_D_stream <= SavedLLR_D_stream;
    if (out_valid_stream)
      for (int i = 0; i < BITS_PER_SYMBOL; i++)
        SavedLLR_D_stream[i] <= {SavedLLR_D_stream[i][1:SYMBOLS-1],LLR_D_stream[i]};
  end
  
int errors = 0;

function CompareLLR_D();
  int differences;
  differences = 0;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      if (SavedLLR_D_stream[i][j] != $shortrealtobits(LLR_D[i][j]))
        differences++;
  errors = differences;
endfunction


task BehavTest(input real LLRVectorIn[BITS_PER_SYMBOL][SYMBOLS]);
 in_valid <= 1;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      begin
        LLRVector[i][j] <= LLRVectorIn[i][j];
      end
  @(posedge clk)
  in_valid <= 0;
  while (out_valid == 0) @(posedge clk);
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      LLRVector[i][j] <= 0.0;
endtask

task StreamTest(input real LLRVectorIn[BITS_PER_SYMBOL][SYMBOLS]);
 in_valid_stream <= 1;
 for (int i = 0; i < SYMBOLS; i++)
   begin
    for (int j = 0; j < BITS_PER_SYMBOL; j++)
      LLRVector_stream[j] <= $shortrealtobits(LLRVectorIn[j][i]);
   @(posedge clk);
   end
 in_valid_stream <= 0;
 LLRVector_stream <= '{ default : 0 };
 while (out_valid_stream == 0) @(posedge clk);
 while (out_valid_stream == 1) @(posedge clk);
 CompareLLR_D();
endtask

typedef real single_llr_array_t[SYMBOLS];
typedef real llr_t[BITS_PER_SYMBOL][SYMBOLS];

function llr_t RandomLLR();
  single_llr_array_t symbols;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    begin
      for (int j = 0; j < SYMBOLS; j++)
        symbols[j] = ($random() > 0.5) ? 1.0 : -1.0;
      RandomLLR[i] = symbols;
    end
endfunction     

task Test();
  llr_t LLRVectorIn = RandomLLR();
  fork
    BehavTest(LLRVectorIn);
    StreamTest(LLRVectorIn);
  join
endtask

initial
  begin
    in_valid = 0;
    LLRVector = '{ default : 0 };
    in_valid_stream = 0;
    LLRVector_stream = '{ default : 0 };
    @(posedge clk);
    Test();
    Test();
    @(posedge clk);
    Test();
    @(posedge clk);
    @(posedge clk);
    Test();
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    Test();
    @(posedge clk);
    Test();
    @(posedge clk);
    Test();
    @(posedge clk);
    Test();
    @(posedge clk);
    Test();
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

bcjr_max_product_behav
#(.BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS))
bcjr_max_product_behav1
(
.trellis,
.in_valid,
.LLRVector,
.out_valid,
.LLR_D
);

stream_bcjr_max_product
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS), .STATES(STATES))
stream_bcjr_max_product1
(
.clk,
.trellis,
.in_valid(in_valid_stream),
.LLRVector(LLRVector_stream),
.out_valid(out_valid_stream),
.LLR_D(LLR_D_stream)
);

endmodule
