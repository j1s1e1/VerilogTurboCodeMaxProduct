`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 04:21:07 PM
// Design Name: 
// Module Name: stream_interleaver
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


module stream_interleaver
#(BITS = 8, int N = 10, DIR = "F")
(
input clk,
interface interleave,
input in_valid,
input [BITS-1:0] data_in,
output logic out_valid = 0,
output logic [BITS-1:0] data_out = 0
);

logic [$clog2(N)-1:0] input_count = 0;
logic [$clog2(N):0] output_count = N;
logic buffer_select = 0;
logic [BITS-1:0] buffer[2][N] = '{ default : 0 };
logic [BITS-1:0] output_data[N];

if (DIR == "F")
  assign output_data = (buffer_select) ? interleave.Forward(buffer[0]) : interleave.Forward(buffer[1]); 
else
  assign output_data = (buffer_select) ? interleave.Reverse(buffer[0]) : interleave.Reverse(buffer[1]); 

always @(posedge clk)
  begin
    input_count <= input_count;
    if (in_valid)
      if (input_count < N-1) 
        input_count <= input_count + 1;
      else
        input_count <= 0;
  end

always @(posedge clk)
  begin
    buffer_select <= buffer_select;
    if (in_valid)
      if (input_count == N-1) 
        buffer_select <= ~buffer_select;
  end
   
always @(posedge clk)
  begin
    buffer <= buffer;
    if (in_valid)
      buffer[buffer_select] <= {buffer[buffer_select][1:N-1],data_in};
  end

always @(posedge clk)
  begin
    output_count <= output_count;
    if (output_count < N)
      output_count <= output_count + 1;
    if (in_valid)
      if (input_count == N-1)
        output_count <= 0;
  end

always @(posedge clk)
  begin
    data_out <= 0;
    if (output_count < N)
      data_out <= output_data[output_count];
  end

always @(posedge clk)
  begin
    out_valid <= 0;
    if (output_count < N)
      out_valid <= 1;
  end
   
endmodule
