`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 02:02:33 PM
// Design Name: 
// Module Name: stream_siso
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


module stream_siso
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, N = 10, SYMBOLS = 10, 
    STATES = 7, HALF_ITER = 0, ALOGORITHM = "MPA")
(
input clk,
interface interleave,
interface interleave_result,
trellis_if trellis,
input in_valid,
input [BITS-1:0] encoder1_data_in[BITS_PER_SYMBOL],
input [BITS-1:0] encoder2_data_in[BITS_PER_SYMBOL],
input [BITS-1:0] extrinsic_in[BITS_PER_SYMBOL],
output logic out_valid,
output logic [BITS-1:0] encoder1_data_out[BITS_PER_SYMBOL],
output logic [BITS-1:0] encoder2_data_out[BITS_PER_SYMBOL],
output logic [BITS-1:0] extrinsic_out[BITS_PER_SYMBOL],
output logic result
);

localparam MAX_PRODUCT_DELAY = SYMBOLS * 4 + 10;
localparam ENCODER_DATA_DELAY = MAX_PRODUCT_DELAY + SYMBOLS + 4;
localparam ENCODED_DATA_PLUS_EXTRINSIC_DELAY = MAX_PRODUCT_DELAY;
localparam EXTRINSIC_DELAY = 0;

typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL];
typedef logic [BITS-1:0] block_t;

llr_t encoder_data = '{ default : 0 };
llr_t encoder_data_d = '{ default : 0 };
llr_t extrinsic_scaled;
llr_t encoder_data_or_encoder_data_flipped;
logic out_valid_scale1;
logic out_valid_llr_vector;
llr_t encoded_data_plus_extrinsic_scaled;
llr_t encoded_data_plus_extrinsic_scaled_d;
logic out_valid_llr_ed_plus_es;
llr_t LLRVector;
logic out_valid_llr_d;
llr_t LLR_D;
llr_t LLR_D_flipped;
logic out_valid_subtract;
llr_t extrinsic_result_minus_input;
logic decoder_bits = 0;
logic decoder_bits_d;
logic decoder_bits_deinterleaved;
llr_t extrinsic_out_p;

always @(posedge clk)
  decoder_bits <= (out_valid_llr_d) ? 
                        (LLR_D[1][BITS-1] == 1) ? 
                                    0 : 
                                    1 :
                                0;

delay #(.DELAY(SYMBOLS+1), .WIDTH(1))
delay_decoder_bits
(
.rstn(1'b1),
.clk(clk),
.a(decoder_bits),
.c(decoder_bits_d)
);       

logic out_valid_decoder_bits;                          

delay #(.DELAY(1), .WIDTH(1))
delay_decoder_bits_calc
(
.rstn(1'b1),
.clk(clk),
.a(out_valid_llr_d),
.c(out_valid_decoder_bits)
);     

logic out_valid_interleave_result;

// Even though only N symbols are required, extra inputs and outputs
// are included for tail bits
stream_interleaver
#(.BITS(1), .N(SYMBOLS), .DIR("R"))
stream_interleaver_result
(
.clk,
.interleave(interleave_result),
.in_valid(out_valid_decoder_bits),
.data_in(decoder_bits),
.out_valid(out_valid_interleave_result),
.data_out(decoder_bits_deinterleaved)
);

assign out_valid = out_valid_interleave_result;

assign result = (out_valid_interleave_result) ? 
                        (HALF_ITER == 0) ? 
                            decoder_bits_d : 
                            decoder_bits_deinterleaved :
                        0;

logic out_valid_extrinsic_interleave[BITS_PER_SYMBOL];                        

for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
  begin
    if (HALF_ITER == 0)
      stream_interleaver
        #(.BITS(BITS), .N(SYMBOLS), .DIR("F"))
        stream_interleaver_extrinsic
        (
        .clk,
        .interleave(interleave),
        .in_valid(out_valid_subtract),
        .data_in(extrinsic_result_minus_input[g]),
        .out_valid(out_valid_extrinsic_interleave[g]),
        .data_out(extrinsic_out_p[g])
        );
    else
      stream_interleaver
        #(.BITS(BITS), .N(SYMBOLS), .DIR("R"))
        stream_interleaver_extrinsic
        (
        .clk,
        .interleave(interleave),
        .in_valid(out_valid_subtract),
        .data_in(extrinsic_result_minus_input[g]),
        .out_valid(out_valid_extrinsic_interleave[g]),
        .data_out(extrinsic_out_p[g])
        );
  end               

always @(posedge clk)
  begin
    encoder_data <= (HALF_ITER == 0) ? encoder1_data_in : encoder2_data_in;
    encoder_data_d <= encoder_data;
  end                        
  
scale_vector 
#(.BITS(BITS), .PRECISION(PRECISION), .QUARTERS(3), .N(BITS_PER_SYMBOL)) 
scale_vector1
(
.clk,
.in_valid,
.a(extrinsic_in),
.out_valid(out_valid_scale1),
.c(extrinsic_scaled)
);
    
add
#(.BITS(BITS), .PRECISION(PRECISION))
add1
(
.rstn(1'b1),
.clk,
.in_valid(out_valid_scale1),
.a(encoder_data[0]),
.b(extrinsic_scaled[0]),
.out_valid(out_valid_llr_vector),
.c(LLRVector[0])
);

delay #(.DELAY(1), .WIDTH(BITS))
delay_llr_vector
(
.rstn(1'b1),
.clk(clk),
.a(encoder_data[1]),
.c(LLRVector[1])
); 

if (ALOGORITHM == "MPA")
stream_bcjr_max_product
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .SYMBOLS(SYMBOLS), .STATES(STATES))
stream_bcjr_max_product1
(
.clk,
.trellis,
.in_valid(out_valid_llr_vector),
.LLRVector,
.out_valid(out_valid_llr_d),
.LLR_D
);

always_comb
  LLR_D_flipped = Flip(LLR_D);
  
assign encoder_data_or_encoder_data_flipped = (HALF_ITER == 1) ? encoder_data : Flip(encoder_data);
 
add_vector
#(.BITS(BITS), .PRECISION(PRECISION), .N(BITS_PER_SYMBOL))
add_vector1
(
.clk,
.in_valid(out_valid_scale1),
.a(encoder_data_or_encoder_data_flipped),
.b(extrinsic_scaled),
.out_valid(out_valid_llr_ed_plus_es),
.c(encoded_data_plus_extrinsic_scaled)
);

subtract_vector
#(.BITS(BITS), .PRECISION(PRECISION), .N(BITS_PER_SYMBOL))
subtract_vector1
(
.clk,
.in_valid(out_valid_llr_d),
.a(LLR_D_flipped),
.b(encoded_data_plus_extrinsic_scaled_d),
.out_valid(out_valid_subtract),
.c(extrinsic_result_minus_input)
);

function llr_t Flip(llr_t data);
  llr_t result;
  for (int i = 0; i < BITS_PER_SYMBOL; i++)
    result[i] = data[BITS_PER_SYMBOL - 1 - i];
  return result;
endfunction

delay_v #(.DELAY(ENCODER_DATA_DELAY), .WIDTH(BITS), .LENGTH(BITS_PER_SYMBOL))
delay_v_encoder1_data
(
.rstn(1'b1),
.clk(clk),
.a(encoder1_data_in),
.c(encoder1_data_out)
); 

delay_v #(.DELAY(ENCODER_DATA_DELAY), .WIDTH(BITS), .LENGTH(BITS_PER_SYMBOL))
delay_v_encoder2_data
(
.rstn(1'b1),
.clk(clk),
.a(encoder2_data_in),
.c(encoder2_data_out)
); 

delay_v #(.DELAY(ENCODED_DATA_PLUS_EXTRINSIC_DELAY), .WIDTH(BITS), .LENGTH(BITS_PER_SYMBOL))
delay_v_encoded_plus_extrinsic_scalde
(
.rstn(1'b1),
.clk(clk),
.a(encoded_data_plus_extrinsic_scaled),
.c(encoded_data_plus_extrinsic_scaled_d)
); 

delay_v #(.DELAY(EXTRINSIC_DELAY), .WIDTH(BITS), .LENGTH(BITS_PER_SYMBOL))
delay_v_extrinsic
(
.rstn(1'b1),
.clk(clk),
.a(extrinsic_out_p),
.c(extrinsic_out)
); 

endmodule
