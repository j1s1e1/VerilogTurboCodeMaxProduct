`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/25/2020 03:22:46 PM
// Design Name: 
// Module Name: max_product_symbol_tb
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


module max_product_symbol_tb();

parameter BITS = 32, PRECISION = "SINGLE", BITS_PER_SYMBOL = 2, STATES = 4, OUTPUT_SYMBOLS = 4;
parameter NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };

trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();


logic clk;
logic in_valid;
logic [BITS-1:0] branch_metric[OUTPUT_SYMBOLS];
logic [BITS-1:0] AlphaMetric[STATES];
logic [BITS-1:0] OldBetaMetric[STATES];
logic out_valid;
logic [BITS-1:0] BetaMetric[STATES];
logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL];
logic out_valid_test;
logic [BITS-1:0] BetaMetric_test[STATES];
logic [BITS-1:0] LLR_D_test[BITS_PER_SYMBOL];

task Test(real bm[], real am[], real obm[]);
  in_valid <= 1;
  for (int i = 0; i < OUTPUT_SYMBOLS; i++)
    branch_metric[i] <= $shortrealtobits(bm[i]);
  for (int i = 0; i < STATES; i++)
    begin
      AlphaMetric[i] <= $shortrealtobits(am[i]);
      OldBetaMetric[i] <= $shortrealtobits(obm[i]);
    end
  @(posedge clk);
  in_valid <= 0;
  repeat (10) @(posedge clk);
  branch_metric <= '{ default : 0 };
  AlphaMetric <= '{ default : 0 };
  OldBetaMetric <= '{ default : 0 };
endtask

initial
  begin
    in_valid <= 0;
    branch_metric <= '{ default : 0 };
    AlphaMetric <= '{ default : 0 };
    OldBetaMetric <= '{ default : 0 };
    @(posedge clk);
    Test('{ 1, 2, 3, 4 }, '{ 5, 6, 7, 8 }, '{ 9, 10,11, 12 });
    @(posedge clk);
    Test('{ 1, 2, 3, 4 }, '{ 3, 8, 4, 9 }, '{ 8, 7, 6, 5 });
    @(posedge clk);
    repeat (10) @(posedge clk);
    $stop;
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end

max_product_symbol
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .STATES(STATES), .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS))
max_product_symbol1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.AlphaMetric,
.OldBetaMetric,
.out_valid,
.BetaMetric,
.LLR_D
);

max_product_symbol_test
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .STATES(STATES), .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS))
max_product_symbol_test1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.AlphaMetric,
.OldBetaMetric,
.out_valid(out_valid_test),
.BetaMetric(BetaMetric_test),
.LLR_D(LLR_D_test)
);

endmodule
