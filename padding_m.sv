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
     logic [511:0] reverse;
        int unsigned half_byte;
        half_byte=bit_length/4;
        for (int i=0;i<half_byte;i=i+1)begin
        reverse[i*4 +:4]=message[(half_byte-1-i)*4 +:4];
        end 
        
    // Initialize to 0
    padded_block = '0;
    // First part: the message itself
//    padded_block[511 -: bit_length] = message;
   padded_block = reverse & ((1 << bit_length) - 1);
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
