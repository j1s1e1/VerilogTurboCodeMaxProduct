`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 03:55:58 PM
// Design Name: 
// Module Name: max_product_behav_tb
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


module max_product_behav_tb();

parameter BITS = 32, PRECISION = "SINGLE", BITS_PER_SYMBOL = 2;
parameter STATES = 4, OUTPUT_SYMBOLS = 4, SYMBOLS = 4;
parameter NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };

trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();

logic clk;
logic in_valid;
logic [BITS-1:0] branch_metric[SYMBOLS][OUTPUT_SYMBOLS];
logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1];
logic out_valid;
logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL][SYMBOLS];
logic out_valid_synth;
logic [BITS-1:0] LLR_D_synth[BITS_PER_SYMBOL][SYMBOLS];

task Test(real bm[SYMBOLS][OUTPUT_SYMBOLS], real am[STATES][SYMBOLS+1]);
  in_valid <= 1;
  for (int i = 0; i < SYMBOLS; i++)
    for (int j = 0; j < OUTPUT_SYMBOLS; j++)
      branch_metric[i][j] <= $shortrealtobits(bm[i][j]);
  for (int i = 0; i < STATES; i++)
    for (int j = 0; j < SYMBOLS+1; j++)
      AlphaMetric[i][j] <= $shortrealtobits(am[i][j]);
  @(posedge clk)
  in_valid <= 0;
  repeat (10 * SYMBOLS) @(posedge clk);
  branch_metric <= '{ default : 0 };
  AlphaMetric <= '{ default : 0 };
endtask

real bm1[SYMBOLS][OUTPUT_SYMBOLS] = '{  '{1, 2, 3, 4},
                                        '{1, 2, 3, 4},
                                        '{1, 2, 3, 4},
                                        '{1, 2, 3, 4}};

real am1[STATES][SYMBOLS+1] = '{  '{     1, 2, 3, 4, 5},
                                  '{-10000, 2, 3, 4, 5},
                                  '{-10000, 2, 3, 4, 5},
                                  '{-10000, 2, 3, 4, 5}};
                                  
typedef logic [NOUT-1:0]  llr_bms_t[STATES][trellis.OUTPUT_BITS][trellis.INPUT_SYMBOLS/2];

initial
  begin
    in_valid <= 0;
    branch_metric <= '{ default : 0 };
    AlphaMetric <= '{ default : 0 };
    @(posedge clk);
    @(posedge clk);
    Test(bm1, am1);
    @(posedge clk);
    repeat(10 * SYMBOLS) @(posedge clk);
    $stop;
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end

max_product_behav
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .STATES(STATES), .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS), .SYMBOLS(SYMBOLS))
max_product_behav1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.AlphaMetric,
.out_valid,
.LLR_D
);

max_product
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .STATES(STATES), .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS), .SYMBOLS(SYMBOLS))
max_product_synth
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.AlphaMetric,
.out_valid(out_valid_synth),
.LLR_D(LLR_D_synth)
);

endmodule
