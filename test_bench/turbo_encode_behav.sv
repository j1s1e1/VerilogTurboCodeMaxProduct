`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 02:45:22 PM
// Design Name: 
// Module Name: turbo_encode_behav
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


module turbo_encode_behav
#(N = 64, NOUT = 2, TAIL_BITS = 0)
(
input clk,
interface interleave,
trellis_if trellis,
input in_valid,
input x[N],
output logic out_valid = 0,
output logic y[1 + 2 * NOUT][N+TAIL_BITS] = '{ default : 0 }
);

logic interleaved[N];
logic encoded1[NOUT][N+TAIL_BITS];
logic encoded2[NOUT][N+TAIL_BITS];

always @(posedge clk)
  begin
    if (in_valid)
      begin
        interleaved = interleave.Forward(x);
        trellis.Encode(x, encoded1, TAIL_BITS);
        trellis.Encode(interleaved, encoded2, TAIL_BITS);
      end
  end

always @(posedge clk)
  out_valid <= in_valid;
  
always @(posedge clk)
  begin
    y <= '{ default : 0 };
    if (in_valid)
      begin
        y[0][0:N-1] <= x;
        for (int i = 0; i < NOUT; i++)
          begin
            y[1 + i] <= encoded1[i];
            y[1 + NOUT + i] <= encoded2[i];
          end
      end
  end
endmodule
