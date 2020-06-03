`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2020 03:52:54 PM
// Design Name: 
// Module Name: stream_bcjr_max_product
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


module stream_bcjr_max_product
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, SYMBOLS = 10, STATES = 7)
(
input clk,
trellis_if trellis,
input in_valid,
input [BITS-1:0] LLRVector[BITS_PER_SYMBOL],
output logic out_valid,
output logic [BITS-1:0] LLR_D[BITS_PER_SYMBOL]
);

/****** Important Note *********/
/* 
   Elements from different locks are interleaved in this module to allow data from 
   different blocks to be processed by the same hardware in different clock cycles.  
   This interleaving of blocks is not the same as block interleaving used for 
   turbo coding.  It is done to accomodate recursive calculations that take more
   than one clock cycle while providing the possibility of using the hardware
   during every clock cycle.
*/

localparam OUTPUT_SYMBOLS = trellis.OUTPUT_SYMBOLS;
localparam BRANCH_METRIC_DELAY = 2;
localparam ALPHA_IIR = 2;
localparam BETA_IIR = 2;

logic [BITS-1:0] branch_metric[OUTPUT_SYMBOLS];
logic out_valid_branch_metrics;

branch_metrics
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS))
branch_metrics1
(
.clk,
.in_valid,
.symbol(LLRVector),
.out_valid(out_valid_branch_metrics),
.branch_metric
);

logic in_valid_stream_alpha;
logic block_start_stream_alpha;
logic out_valid_stream_alpha;
logic [BITS-1:0] alpha_metric_interleaved_blocks[STATES];

logic out_valid_interleave_branch_metrics;
logic [BITS-1:0] branch_metric_interleaved[OUTPUT_SYMBOLS];

interleave_block_input_vector
#(.BITS(BITS), .IIR(ALPHA_IIR), .N(SYMBOLS), .V(OUTPUT_SYMBOLS))
interleave_block_input_vector1
(
.clk,
.in_valid(out_valid_branch_metrics),
.data_in(branch_metric),
.out_valid(out_valid_interleave_branch_metrics),
.block_start(block_start_stream_alpha),
.data_out(branch_metric_interleaved)
);

assign in_valid_stream_alpha = out_valid_interleave_branch_metrics;

stream_alpha
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES), .BITS_PER_SYMBOL(BITS_PER_SYMBOL),
    .SYMBOLS(SYMBOLS))
stream_alpha1
(
.clk,
.trellis,
.in_valid(in_valid_stream_alpha),
.block_start(block_start_stream_alpha),
.branch_metric(branch_metric_interleaved),
.out_valid(out_valid_stream_alpha),
.AlphaMetric(alpha_metric_interleaved_blocks)
);

logic out_valid_alpha_deinterleaved;
logic [BITS-1:0] alpha_deinterleaved[STATES];

deinterleave_block_output_vector
#(.BITS(BITS), .IIR(BETA_IIR), .N(SYMBOLS), .V(STATES))
deinterleave_block_output_vector_alpha
(
.clk,
.in_valid(out_valid_stream_alpha),
.data_in(alpha_metric_interleaved_blocks),
.out_valid(out_valid_alpha_deinterleaved),
.data_out(alpha_deinterleaved)
);

logic out_valid_reverse_bm;
logic [BITS-1:0] branch_metric_reversed[OUTPUT_SYMBOLS];

reverse_order_vector
#(.BITS(BITS), .N(SYMBOLS), .V(OUTPUT_SYMBOLS))
reverse_order_vector_bm
(
.clk,
.in_valid(out_valid_branch_metrics),
.data_in(branch_metric),
.out_valid(out_valid_reverse_bm),
.data_out(branch_metric_reversed)
);

logic out_valid_interleave_blocks_reversed;
logic block_start_interleaved_reversed;
logic [BITS-1:0] branch_metric_interleaved_reversed[OUTPUT_SYMBOLS];

interleave_block_input_vector
#(.BITS(BITS), .IIR(BETA_IIR), .N(SYMBOLS), .V(OUTPUT_SYMBOLS))
interleave_block_input_vector_bm_reversed
(
.clk,
.in_valid(out_valid_reverse_bm),
.data_in(branch_metric_reversed),
.out_valid(out_valid_interleave_blocks_reversed),
.block_start(block_start_interleaved_reversed),
.data_out(branch_metric_interleaved_reversed)
);

logic out_valid_beta;
logic [BITS-1:0] BetaMetric[STATES];

stream_beta
#(.BITS(BITS), .PRECISION(PRECISION), .STATES(STATES), .BITS_PER_SYMBOL(BITS_PER_SYMBOL),
    .SYMBOLS(SYMBOLS))
stream_beta1
(
.clk,
.trellis,
.in_valid(out_valid_interleave_blocks_reversed),
.block_start(block_start_interleaved_reversed),
.branch_metric(branch_metric_interleaved_reversed),
.out_valid(out_valid_beta),
.BetaMetric(BetaMetric)
);

logic out_valid_beta_deinterleaved;
logic [BITS-1:0] beta_deinterleaved[STATES];

deinterleave_block_output_vector
#(.BITS(BITS), .IIR(BETA_IIR), .N(SYMBOLS), .V(STATES))
deinterleave_block_output_vector_beta
(
.clk,
.in_valid(out_valid_beta),
.data_in(BetaMetric),
.out_valid(out_valid_beta_deinterleaved),
.data_out(beta_deinterleaved)
);

logic out_valid_reverse_beta;
logic [BITS-1:0] beta_reversed[STATES];

reverse_order_vector
#(.BITS(BITS), .N(SYMBOLS), .V(STATES))
reverse_order_vector_beta
(
.clk,
.in_valid(out_valid_beta_deinterleaved),
.data_in(beta_deinterleaved),
.out_valid(out_valid_reverse_beta),
.data_out(beta_reversed)
);

logic out_valid_bm_deinterleaved;
logic [BITS-1:0] branch_metric_reversed2[OUTPUT_SYMBOLS];

deinterleave_block_output_vector
#(.BITS(BITS), .IIR(BETA_IIR), .N(SYMBOLS), .V(OUTPUT_SYMBOLS))
deinterleave_branch_metric_interleaved_reversed
(
.clk,
.in_valid(out_valid_interleave_blocks_reversed),
.data_in(branch_metric_interleaved_reversed),
.out_valid(out_valid_bm_deinterleaved),
.data_out(branch_metric_reversed2)
);

logic out_valid_reverse_beta_bm;
logic [BITS-1:0] branch_metric_d[OUTPUT_SYMBOLS];

reverse_order_vector
#(.BITS(BITS), .N(SYMBOLS), .V(OUTPUT_SYMBOLS))
reverse_order_vector_beta_bm
(
.clk,
.in_valid(out_valid_bm_deinterleaved),
.data_in(branch_metric_reversed2),
.out_valid(out_valid_reverse_beta_bm),
.data_out(branch_metric_d)
);

logic [BITS-1:0] alpha_deinterleaved_d[STATES];

delay_v
#(.DELAY(2*SYMBOLS+2), .WIDTH(BITS), .LENGTH(STATES))
delay_v_beta
(
.rstn(1'b1),
.clk,
.a(alpha_deinterleaved),
.c(alpha_deinterleaved_d)
);

// All input data should be back in standard block order when input into this module
stream_max_product
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), 
    .STATES(STATES), .OUTPUT_SYMBOLS(OUTPUT_SYMBOLS), .SYMBOLS(SYMBOLS))
stream_max_product1
(
.clk,
.trellis,
.in_valid(out_valid_reverse_beta),
.branch_metric(branch_metric_d),
.AlphaMetric(alpha_deinterleaved_d),
.BetaMetric(beta_reversed),
.out_valid,
.LLR_D
);

endmodule
