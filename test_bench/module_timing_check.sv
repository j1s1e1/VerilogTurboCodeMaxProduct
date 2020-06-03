`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2020 10:13:33 AM
// Design Name: 
// Module Name: module_timing_check
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


module module_timing_check
(
input clk,
input in_valid,
input out_valid,
output int count = -1
);

int count_temp = 0;
logic active = 0;

always @(posedge clk)
  begin
    active <= active;
    if (in_valid)
      active <= 1;
    if (out_valid)
      active <= 0;
  end

always @(posedge clk)
  begin
    if (active)
      count_temp <= count_temp + 1;
    else
      count_temp <= 0;
  end

always @(posedge clk)
  begin
    count <= count;
    if (!active)
      if (count_temp != 0)
        count <= count_temp;
  end
  
endmodule
