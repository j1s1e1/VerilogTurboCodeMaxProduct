`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 02:34:21 AM
// Design Name: 
// Module Name: branch_metric
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


module branch_metric
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, OUTPUT_SYMBOL = 0)
(
input clk,
input in_valid,
input [BITS-1:0] symbol[BITS_PER_SYMBOL],
output logic  out_valid,
output logic  [BITS-1:0] branch_metric = 0
);

localparam EXP_BITS = (PRECISION == "HALF") ? 5 : 8;
localparam MANTISSA_BITS = BITS-1-EXP_BITS;
logic  [BITS-1:0] branch_metric_x_2;
logic [EXP_BITS-1:0] exponent;     
logic [EXP_BITS-1:0] exponent_half;
logic [BITS-1:0] vin[BITS_PER_SYMBOL];

assign exponent = branch_metric_x_2[BITS-2 -:EXP_BITS];                   
assign exponent_half = (exponent != 0) ? exponent - 1 : 0;
always_comb
  if (out_valid) 
    branch_metric = {branch_metric_x_2[BITS-1],exponent_half,branch_metric_x_2[MANTISSA_BITS-1:0]};

for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
  assign vin[g] = (((OUTPUT_SYMBOL >> g) & 1) == 1) ? symbol[g] : {~symbol[g][BITS-1],symbol[g][BITS-2:0]};

sum_vector
#(.BITS(BITS), .PRECISION(PRECISION), .N(BITS_PER_SYMBOL))
sum_vector1
(
.clk,
.in_valid,
.vin,
.out_valid,
.sum(branch_metric_x_2)
);

endmodule
