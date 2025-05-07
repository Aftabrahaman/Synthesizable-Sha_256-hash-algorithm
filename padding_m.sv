`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2025 04:55:22 PM
// Design Name: 
// Module Name: padding_m
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


module padding_m(
input logic [511:0] m,input int unsigned siz,output logic [511:0] pm 
);
    function logic [511:0] pad_message(input logic [511:0] message, input int  unsigned   bit_length);
    logic [511:0] padded_block;
//    int unsigned zero_pad_length; 
//    // Calculate how many zeros we need to add after the '1' bit
//    // We need 64 bits at the end for length, plus at least one '1' bit
//    zero_pad_length = 512 - (bit_length % 512) - 1 - 64;
    
    // Initialize to 0
    padded_block = '0;
    // First part: the message itself
//    padded_block[511 -: bit_length] = message;
   padded_block = message & ((1 << bit_length) - 1);
    // Append '1' bit
    padded_block[bit_length] = 1'b1;
    
//    // Append zeros
//    padded_block[511 - bit_length - 1 -: zero_pad_length] = '0;
//    for (int i=0;i<zero_pad_length;i=i+1)begin
//    padded_block[bit_length+1+i]='0;
//    end
    
    // Append length in bits (big-endian)
    padded_block[511:448] = bit_length;
    
    return padded_block;
endfunction

always_comb begin
pm=pad_message(m,siz);
end
endmodule
