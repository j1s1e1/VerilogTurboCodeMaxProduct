`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 08:52:12 PM
// Design Name: 
// Module Name: soft_in_soft_out
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


module soft_in_soft_out
#(BITS = 16, PRECISION = "HALF", BITS_PER_SYMBOL = 2, N = 10, SYMBOLS = 10, 
    STATES = 7, HALF_ITER = 0, ALOGORITHM = "MPA")
(
input clk,
interface interleave,
interface interleave_result,
trellis_if trellis,
input in_valid,
input [BITS-1:0] encoder1_data_in[BITS_PER_SYMBOL][SYMBOLS],
input [BITS-1:0] encoder2_data_in[BITS_PER_SYMBOL][SYMBOLS],
input [BITS-1:0] extrinsic_in[BITS_PER_SYMBOL][SYMBOLS],
output logic out_valid,
output logic [BITS-1:0] encoder1_data_out[BITS_PER_SYMBOL][SYMBOLS],
output logic [BITS-1:0] encoder2_data_out[BITS_PER_SYMBOL][SYMBOLS],
output logic [BITS-1:0] extrinsic_out[BITS_PER_SYMBOL][SYMBOLS],
output logic result[N]
);

localparam MAX_PRODUCT_DELAY = SYMBOLS * (STATES + 2) + $clog2(STATES);
localparam DELAY = 2 * SYMBOLS + 3 + MAX_PRODUCT_DELAY;
localparam EXTRINSIC_DELAY = 0;

typedef logic [BITS-1:0] llr_t[BITS_PER_SYMBOL][SYMBOLS];
typedef logic [BITS-1:0] block_t[N];

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
logic decoder_bits[N];
logic decoder_bits_deinterleaved[N];
logic zeros[N] = '{ default : 0 };
llr_t extrinsic_out_p;

for (genvar g = 0; g < N; g++)
  always @(posedge clk)
    decoder_bits[g] <= (out_valid_llr_d) ? 
                                (LLR_D[1][g][BITS-1] == 1) ? 
                                    0 : 
                                    1 :
                                0;
  
assign decoder_bits_deinterleaved = interleave_result.Reverse(decoder_bits);

assign out_valid = out_valid_subtract;

assign result = (out_valid) ? 
                        (HALF_ITER == 0) ? 
                            decoder_bits : 
                            decoder_bits_deinterleaved :
                        zeros;

for (genvar g = 0; g < BITS_PER_SYMBOL; g++)
  begin
    if (HALF_ITER == 0)
      assign extrinsic_out_p[g] = interleave.Forward(extrinsic_result_minus_input[g]);
    else
      assign extrinsic_out_p[g] = interleave.Reverse(extrinsic_result_minus_input[g]);
  end                   

always @(posedge clk)
  begin
    encoder_data <= (HALF_ITER == 0) ? encoder1_data_in : encoder2_data_in;
    encoder_data_d <= encoder_data;
  end                        
  
scale_matrix 
#(.BITS(BITS), .PRECISION(PRECISION), .QUARTERS(3), .R(BITS_PER_SYMBOL), .C(SYMBOLS)) 
scale_matrix1
(
.clk,
.in_valid,
.a(extrinsic_in),
.out_valid(out_valid_scale1),
.c(extrinsic_scaled)
);
    
add_vector
#(.BITS(BITS), .PRECISION(PRECISION), .N(SYMBOLS))
add_vector1
(
.clk,
.in_valid(out_valid_scale1),
.a(encoder_data[0]),
.b(extrinsic_scaled[0]),
.out_valid(out_valid_llr_vector),
.c(LLRVector[0])
);

delay_v #(.DELAY(1), .WIDTH(BITS), .LENGTH(SYMBOLS))
delay_v_llr_vector
(
.clk(clk),
.rstn(1'b1),
.a(encoder_data[1]),
.c(LLRVector[1])
); 

if (ALOGORITHM == "MPA")
bcjr_max_product
#(.BITS(BITS), .PRECISION(PRECISION), .BITS_PER_SYMBOL(BITS_PER_SYMBOL), .STATES(STATES), .SYMBOLS(SYMBOLS))
bcjr_max_product1
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
 
add_matrix
#(.BITS(BITS), .PRECISION(PRECISION), .N(BITS_PER_SYMBOL), .M(SYMBOLS))
add_matrix1
(
.clk,
.in_valid(out_valid_scale1),
.a(encoder_data_or_encoder_data_flipped),
.b(extrinsic_scaled),
.out_valid(out_valid_llr_ed_plus_es),
.c(encoded_data_plus_extrinsic_scaled)
);

subtract_matrix
#(.BITS(BITS), .PRECISION(PRECISION), .R(BITS_PER_SYMBOL), .C(SYMBOLS))
subtract_matrix1
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
    for (int j = 0; j < SYMBOLS; j++)
      result[i][j] = data[BITS_PER_SYMBOL - 1 - i][j];
  return result;
endfunction

delay_m #(.DELAY(DELAY), .WIDTH(BITS), .R(BITS_PER_SYMBOL), .C(SYMBOLS))
delay_m_encoder1_data
(
.clk(clk),
.a(encoder1_data_in),
.c(encoder1_data_out)
); 

delay_m #(.DELAY(DELAY), .WIDTH(BITS), .R(BITS_PER_SYMBOL), .C(SYMBOLS))
delay_m_encoder2_data
(
.clk(clk),
.a(encoder2_data_in),
.c(encoder2_data_out)
); 

delay_m #(.DELAY(DELAY-3), .WIDTH(BITS), .R(BITS_PER_SYMBOL), .C(SYMBOLS))
delay_m_encoded_plus_extrinsic_scalde
(
.clk(clk),
.a(encoded_data_plus_extrinsic_scaled),
.c(encoded_data_plus_extrinsic_scaled_d)
); 

delay_m #(.DELAY(EXTRINSIC_DELAY), .WIDTH(BITS), .R(BITS_PER_SYMBOL), .C(SYMBOLS))
delay_m_extrinsic
(
.clk(clk),
.a(extrinsic_out_p),
.c(extrinsic_out)
); 

endmodule
