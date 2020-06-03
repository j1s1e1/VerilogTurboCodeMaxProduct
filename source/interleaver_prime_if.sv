`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 02:57:21 PM
// Design Name: 
// Module Name: interleaver_prime_if
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


interface interleaver_prime_if #(BITS = 8, int N = 10, P = 3, TAIL_BITS = 0);
  typedef logic [BITS-1:0] packet_t[N + TAIL_BITS];

generate                // This does not work in an interface in simulation !!
if ((N % P) == 0)
  $error("This interleaver fails if N mod P == 0");
endgenerate
  
  function packet_t Forward(packet_t data);
    for (int i = 0; i < N + TAIL_BITS; i++)
      if (i >= N)
        Forward[i] = data[i];
      else
        Forward[i] = data[(P * i) % N];
  endfunction
  
  function packet_t Reverse(packet_t data);
    for (int i = 0; i < N + TAIL_BITS; i++)
      if (i >= N)
         Reverse[i] = data[i];
      else
        Reverse[(P * i) % N] = data[i];
  endfunction
  
endinterface
