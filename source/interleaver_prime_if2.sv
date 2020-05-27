`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 12:07:40 PM
// Design Name: 
// Module Name: interleaver_prime_if2
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
// 
//  Duplicate of interleaver_prime_if due to tool bug
//
//////////////////////////////////////////////////////////////////////////////////


interface interleaver_prime_if2#(BITS = 8, int N = 10, P = 3);
  typedef logic [BITS-1:0] packet_t[N];
  
  function packet_t Forward(packet_t data);
    for (int i = 0; i < N; i++)
      Forward[i] = data[(P * i) % N];
  endfunction
  
  function packet_t Reverse(packet_t data);
    for (int i = 0; i < N; i++)
      Reverse[(P * i) % N] = data[i];
  endfunction
  
endinterface