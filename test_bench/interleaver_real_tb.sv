`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 06:14:01 PM
// Design Name: 
// Module Name: interleaver_real_tb
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


module interleaver_real_tb();

parameter N = 10;
parameter type DATA_TYPE = logic [31:0];

logic clk;
interleaver_prime_if #(.DATA_TYPE(DATA_TYPE), .N(N), .P(3)) interleave();

real input1[N] = '{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
real output1[N];

task Test(real dataIn[N], output real dataOut[N]);
  logic [31:0] inData[N];
  logic [31:0] outData[N];
  for (int i = 0; i < N; i++)
    inData[i] = $shortrealtobits(dataIn[i]);
  outData = interleave.Forward(inData);
  for (int i = 0; i < N; i++)
    dataOut[i] = $bitstoshortreal(outData[i]);
endtask

initial
  begin
    @(posedge clk);
    Test(input1, output1);
    @(posedge clk);
    $stop;
  end
  
initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end

endmodule
