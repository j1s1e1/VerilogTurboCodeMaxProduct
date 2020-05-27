`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2020 10:49:11 AM
// Design Name: 
// Module Name: alpha_tb
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


module alpha_tb();

parameter BITS = 32, PRECISION = "SINGLE", STATES = 4, BITS_PER_SYMBOL = 2, SYMBOLS = 10;
parameter NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };

typedef real llr_t[BITS_PER_SYMBOL][SYMBOLS];

logic clk;
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();
logic in_valid;
logic [BITS-1:0] LLRVector[BITS_PER_SYMBOL][SYMBOLS];
logic out_valid = 0;
logic [BITS-1:0] AlphaMetric[STATES][SYMBOLS+1];

llr_t LLRVector1 = '{ '{ 1, -1, 1, -1, 1, -1, 1, -1, 1, -1 },
                      '{ 1, -1, 1, -1, 1, -1, 1, -1, 1, -1 }};
                      
llr_t LLRVector2 = '{ '{ 1, 1, 1, -1, -1, -1, 1, 1, 1, -1 },
                      '{ 1, -1, 1, -1, 1, -1, 1, -1, 1, -1 }};
                      
llr_t LLRVector3 = '{ '{ -1, 1, -1, 1, -1, 1, -1, 1, -1, 1 },
                      '{ -1, 1, -1, 1, -1, 1, -1, 1, -1, 1 }};     

llr_t LLRVector4 = '{ '{ 1, -1, 1, -1, 1, -1, 1, -1, 1, -1 },
                      '{ -1, 1, -1, 1, -1, 1, -1, 1, -1, 1 }};                                       
                     
task Test(llr_t llr);
  in_valid <= 1;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    for (int j = 0; j < SYMBOLS; j++)
      LLRVector[i][j] <= $shortrealtobits(llr[i][j]);
  @(posedge clk);
  in_valid <= 0;
  //LLRVector <= '{ default : 0 };
endtask                      

initial
  begin
    in_valid <= 0;
    LLRVector <= '{ default : 0 };
    @(posedge clk);
    Test(LLRVector1);
    @(posedge clk);
    repeat(5 * SYMBOLS) @(posedge clk);
    @(posedge clk);
    Test(LLRVector2);
    @(posedge clk);
    @(posedge clk);
    repeat(5 * SYMBOLS) @(posedge clk);
    Test(LLRVector3);
    @(posedge clk);
    @(posedge clk);
    repeat(5 * SYMBOLS) @(posedge clk);
    Test(LLRVector4);
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

endmodule
