`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/25/2020 04:04:58 PM
// Design Name: 
// Module Name: max_product_symbol_state_tb
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


module max_product_symbol_state_tb();

parameter BITS = 32, PRECISION = "SINGLE", INPUT_SYMBOLS = 2, OUTPUT_BITS = 2, STATES = 4, STATE = 2;
parameter NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };

trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();

logic clk;
logic in_valid;
logic [BITS-1:0] branch_metric[INPUT_SYMBOLS];
logic [BITS-1:0] AlphaMetric;
logic [BITS-1:0] OldBetaMetric[INPUT_SYMBOLS];
logic out_valid;
logic [BITS-1:0] BetaMetric;
logic [BITS-1:0] llr_0_out[INPUT_SYMBOLS];
logic [BITS-1:0] llr_1_out[INPUT_SYMBOLS];
logic out_valid_test;
logic [BITS-1:0] BetaMetric_test;
logic [BITS-1:0] llr_0_out_test[INPUT_SYMBOLS];
logic [BITS-1:0] llr_1_out_test[INPUT_SYMBOLS];

task Test(real bm[], real a, real obm[]);
  in_valid <= 1;
  for (int i = 0; i < INPUT_SYMBOLS; i++)
    begin
      branch_metric[i] <= $shortrealtobits(bm[i]);
      OldBetaMetric[i] <= $shortrealtobits(obm[i]);
    end
  AlphaMetric <= $shortrealtobits(a);
  @(posedge clk);
  in_valid <= 0;
  repeat(10) @(posedge clk);
endtask

initial
  begin
    in_valid <= 0;
    branch_metric <= '{ default : 0 };
    AlphaMetric <= 0;
    OldBetaMetric <= '{ default : 0 };
    @(posedge clk);
    Test( '{ 5, 7 }, 13, '{ 8, 3 });
    repeat (10) @(posedge clk);
    $stop;
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
max_product_symbol_state
#(.BITS(BITS), .PRECISION(PRECISION), .INPUT_SYMBOLS(INPUT_SYMBOLS), .OUTPUT_BITS(OUTPUT_BITS), .STATE(STATE))
max_product_symbol_state1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.AlphaMetric,
.OldBetaMetric,
.out_valid,
.BetaMetric,
.llr_0_out,
.llr_1_out
);

max_product_symbol_state_test
#(.BITS(BITS), .PRECISION(PRECISION), .INPUT_SYMBOLS(INPUT_SYMBOLS), .OUTPUT_BITS(OUTPUT_BITS), .STATE(STATE))
max_product_symbol_state_test1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.AlphaMetric,
.OldBetaMetric,
.out_valid(out_valid_test),
.BetaMetric(BetaMetric_test),
.llr_0_out(llr_0_out_test),
.llr_1_out(llr_1_out_test)
);

endmodule
