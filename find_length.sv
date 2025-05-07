`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2025 04:36:39 PM
// Design Name: 
// Module Name: find_length
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


module find_length(
input logic [127:0][3:0] mess,
input [3:0] last_word,
output int unsigned  size
 );
   
function int  find_length(input logic [127:0][3:0] m_input);
    for (int i = 0; i <128; i++) begin
        if (m_input[i] == last_word) begin
            return (i*4)+4;  // Length is position + 1 (since indexing starts at 0)
        end
    end
    return 0;  // If all zeros
endfunction

always_comb begin
size=find_length(mess);
end
endmodule
