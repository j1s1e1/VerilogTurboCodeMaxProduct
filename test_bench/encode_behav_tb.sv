`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 11:22:26 AM
// Design Name: 
// Module Name: encode_behav_tb
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


module encode_behav_tb();

parameter BITS_PER_SYMBOL = 2, SYMBOLS = 5;
parameter STATES = 4, NIN = 1, NOUT = 2, RECURSIVE = 7;
parameter int POLY[NOUT] = '{ 5, 7 };
trellis_if #(.STATES(STATES), .NIN(NIN), .NOUT(NOUT), .RECURSIVE(RECURSIVE), .POLY(POLY)) trellis();

logic input1[] = '{ 1, 1, 1, 0, 0, 0, 1, 1, 1, 0 };;
logic output1[][];

function void OutputMatrix(input logic data[][]);
  for (int i = 0; i < data.size(); i++)
    begin
      for (int j = 0; j < data[i].size(); j++)
        $write("%d ", data[i][j]);
      $write("\n");
    end
    
endfunction

initial
  begin
    trellis.Encode(input1, output1);
    OutputMatrix(output1);
    $stop;
  end

endmodule
