`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2020 01:02:56 PM
// Design Name: 
// Module Name: stream_alpha_tb
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

module stream_alpha_tb();

parameter BITS = 32, PRECISION = "SINGLE", STATES = 4, BITS_PER_SYMBOL = 2, SYMBOLS = 20;
parameter NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };

typedef real single_llr_array_t[SYMBOLS];
typedef real llr_t[BITS_PER_SYMBOL][SYMBOLS];

logic clk;
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
logic in_valid;
logic [BITS-1:0] LLRVector[BITS_PER_SYMBOL][SYMBOLS];
logic out_valid = 0;
logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1];  

logic in_valid_bm;
logic [BITS-1:0] LLRVector_bm[BITS_PER_SYMBOL];
logic out_valid_bm;
logic [BITS-1:0] branch_metric[trellis.OUTPUT_SYMBOLS];

logic in_valid_stream_alpha;
logic block_start_stream_alpha;
logic [BITS-1:0] branch_metric_interleaved[trellis.OUTPUT_SYMBOLS];
logic out_valid_stream_alpha;
logic [BITS-1:0] alpha_metric_interleaved_blocks[STATES];
logic [BITS-1:0] SavedStreamedAlphaMetric[STATES][SYMBOLS] = '{ default : 0 };  

logic out_valid_alpha_deinterleaved;
logic [BITS-1:0] alpha_deinterleaved[STATES];

always @(posedge clk)
  begin
    SavedStreamedAlphaMetric <= SavedStreamedAlphaMetric;
    if (out_valid_alpha_deinterleaved)
      for (int i = 0; i < STATES; i++)
        SavedStreamedAlphaMetric[i] <= {SavedStreamedAlphaMetric[i][1:SYMBOLS-1],alpha_deinterleaved[i]};
  end
  
logic out_valid_alpha_deinterleaved_d = 0;
int errors = 0;

always @(posedge clk)
  out_valid_alpha_deinterleaved_d <= out_valid_alpha_deinterleaved;

function CheckForDifferences();
  int differences;
  differences = 0;
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < SYMBOLS; j++)
      if (SavedStreamedAlphaMetric[i][j] != AlphaMetric[i][j])
        differences++;
  errors = differences;
endfunction

always @(posedge clk)
  begin
    if (out_valid_alpha_deinterleaved_d == 1)
      if (out_valid_alpha_deinterleaved == 0)
        CheckForDifferences();
  end  

function llr_t RandomLLR();
  single_llr_array_t symbols;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    begin
      for (int j = 0; j < SYMBOLS; j++)
        symbols[j] = ($random() > 0.5) ? 1.0 : -1.0;
      RandomLLR[i] = symbols;
    end
endfunction          

task StreamAlphaTest(llr_t llr);
  in_valid_bm <= 1;
  for (int i = 0; i < SYMBOLS; i++)
    begin
      for (int j = 0; j < BITS_PER_SYMBOL; j++)
        LLRVector_bm[j] <= $shortrealtobits(llr[j][i]);
      @(posedge clk);
    end
  in_valid_bm <= 0;
  LLRVector_bm <= '{ default : 0 };
endtask

task AlphaTest(llr_t llr);
  in_valid <= 1;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      LLRVector[i][j] <= $shortrealtobits(llr[i][j]);
  @(posedge clk);
  in_valid <= 0;
  //LLRVector <= '{ default : 0 };
endtask                   
                     
task Test();
  llr_t llr = RandomLLR();
  fork
    StreamAlphaTest(llr);
    AlphaTest(llr);
  join
endtask                      

initial
  begin
    in_valid <= 0;
    LLRVector <= '{ default : 0 };
    in_valid_bm <= 0;
    LLRVector_bm <= '{ default : 0 };
    @(posedge clk);
    Test();
    @(posedge clk);
    repeat(5 * SYMBOLS) @(posedge clk);
    @(posedge clk);
    Test();
    @(posedge clk);
    @(posedge clk);
    repeat(5 * SYMBOLS) @(posedge clk);
    Test();
    @(posedge clk);
    @(posedge clk);
    repeat(5 * SYMBOLS) @(posedge clk);
    Test();
    @(posedge clk);
    @(posedge clk);
    repeat(5 * SYMBOLS) @(posedge clk);
    $stop;
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
alpha
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS))
alpha1
(
.clk,
.trellis,
.in_valid,
.LLRVector,
.out_valid,
.AlphaMetric
);

branch_metrics
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .OUTPUT_SYMBOLS(trellis.OUTPUT_SYMBOLS))
branch_metrics1
(
.clk,
.in_valid(in_valid_bm),
.symbol(LLRVector_bm),
.out_valid(out_valid_bm),
.branch_metric
);

parameter ALPHA_IIR = 2;

interleave_block_input_vector
#(.BITS(BITS), .IIR(ALPHA_IIR), .N(SYMBOLS), .V(trellis.OUTPUT_SYMBOLS))
interleave_block_input_vector1
(
.clk,
.in_valid(out_valid_bm),
.data_in(branch_metric),
.out_valid(in_valid_stream_alpha),
.block_start(block_start_stream_alpha),
.data_out(branch_metric_interleaved)
);

stream_alpha
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES), .BITS_PER_SYMBOL(BITS_PER_SYMBOL),
    .SYMBOLS(SYMBOLS))
stream_alpha1
(
.clk,
.trellis,
.in_valid(in_valid_stream_alpha),
.block_start(block_start_stream_alpha),
.branch_metric(branch_metric_interleaved),
.out_valid(out_valid_stream_alpha),
.AlphaMetric(alpha_metric_interleaved_blocks)
);

deinterleave_block_output_vector
#(.BITS(BITS), .IIR(ALPHA_IIR), .N(SYMBOLS), .V(STATES))
deinterleave_block_output_vector_alpha
(
.clk,
.in_valid(out_valid_stream_alpha),
.data_in(alpha_metric_interleaved_blocks),
.out_valid(out_valid_alpha_deinterleaved),
.data_out(alpha_deinterleaved)
);

endmodule
