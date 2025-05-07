`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2025 04:46:24 PM
// Design Name: 
// Module Name: bit_to_byte
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


module bit_to_byte(
 input logic [511:0] message_input,
 output logic [127:0][3:0] data_out
    );
    
  function logic[127:0][3:0] data_func(input logic [511:0] message);
logic[127:0][3:0] data ;
for (int i=0;i<128;i=i+1)begin    
data[i]=message[(i*4) +: 4];
end
return data;
endfunction

always_comb begin
data_out=data_func(message_input);
end
endmodule
