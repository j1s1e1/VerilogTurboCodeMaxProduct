`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 01:03:56 PM
// Design Name: 
// Module Name: alpha_element_behav_tb
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


module alpha_element_behav_tb();

parameter BITS = 32, PRECISION = "SINGLE", STATES = 4, BITS_PER_SYMBOL = 2;
parameter NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();

logic clk;
logic in_valid;
logic [BITS-1:0] branch_metric[trellis.OUTPUT_SYMBOLS];
logic [BITS-1:0] previousAlpha[STATES];
logic out_valid;
logic [BITS-1:0] AlphaMetric[STATES];
logic out_valid_synth;
logic [BITS-1:0] AlphaMetric_synth[STATES];

task Test(real bm[trellis.OUTPUT_SYMBOLS], real pa[STATES]);
  in_valid <= 1;
  for(int i = 0; i < trellis.OUTPUT_SYMBOLS; i++)
    branch_metric[i] <= $shortrealtobits(bm[i]);
  for(int i = 0; i < STATES; i++)
    previousAlpha[i] <= $shortrealtobits(pa[i]);    
  @(posedge clk);
  in_valid <= 0;
  branch_metric <= '{ default : 0 };
  previousAlpha <= '{ default : 0 };
endtask

initial
  begin
    in_valid = 0;
    branch_metric = '{ default : 0 };
    previousAlpha = '{ default : 0 };
    @(posedge clk);
    Test('{ 1, 2, 3, 4}, '{ 1, 2, 3, 4});
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

alpha_element_behav
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES), .BITS_PER_SYMBOL(BITS_PER_SYMBOL))
alpha_element_behav1
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.previousAlpha,
.out_valid,
.AlphaMetric
);

alpha_element
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES))
alpha_element_synth
(
.clk,
.trellis,
.in_valid,
.branch_metric,
.previousAlpha,
.out_valid(out_valid_synth),
.AlphaMetric(AlphaMetric_synth)
);

endmodule
