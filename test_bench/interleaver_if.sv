`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 03:21:06 PM
// Design Name: 
// Module Name: interleaver_if
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


interface interleaver_if #(N = 10);
// Dummy file to be replaced by real interleavers
typedef logic packet_t[N];
  
  function packet_t Forward(packet_t data);
    for (int i = 0; i < N; i++)
      Forward[i] = data[(i + 1) % N];
  endfunction
  
  function packet_t Reverse(packet_t data);
    for (int i = 0; i < N; i++)
      Reverse[(N + i - 1) % N] = data[i];
  endfunction
endinterface
