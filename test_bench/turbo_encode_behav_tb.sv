`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 03:04:00 PM
// Design Name: 
// Module Name: turbo_encode_behav_tb
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


module turbo_encode_behav_tb();

parameter N = 10, TAIL_BITS = 2;

parameter STATES = 4, NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };  // Not including systematic here
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), 
    .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();

logic clk;
interleaver_prime_if #(.N(N), .P(3)) interleave();
logic in_valid;
logic x[N];
logic out_valid;
logic y[1 + 2 * NOUT][N+TAIL_BITS];

logic x1[N] = '{ 1, 1, 1, 0, 0, 0, 1, 1, 1, 0 };

task Test(input logic xin[N]);
  in_valid <= 1;
  x <= xin;
  @(posedge clk)
  in_valid <= 0;
  x <= '{ default : 0 };
endtask

initial
  begin
    in_valid <= 0;
    x <= '{ default : 0 };
    @(posedge clk);
    Test(x1);
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
.interleave,
.trellis,
.in_valid,
.x,
.out_valid,
.y
);

endmodule
