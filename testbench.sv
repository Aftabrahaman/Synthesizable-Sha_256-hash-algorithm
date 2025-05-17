// Code your testbench here
// or browse Examples
`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
interface sha256();
     logic clk;
     logic reset_n;
  logic [511:0] message_block; 
     logic [3:0] first_word;
     logic block_valid;
    logic [255:0] hash;
    logic hash_valid;
    endinterface
    
    
class gen; ///////////////////////Generating  the message signal  
 virtual sha256 vif;
  
task reset();
vif.reset_n<=1'b0;
  repeat(2)@(posedge vif.clk);
vif.reset_n<=1'b1;
endtask

task body();
  @(posedge vif.clk);
  vif.message_block <= 512'h6aadcf; ////////sending first data 
  vif.first_word <= 4'h6;
  vif.block_valid <= 1'b1;
  $display("receiving time %0t",$time);
  
  // Wait until hash_valid goes high (block processed)
  wait(vif.hash_valid);
  @(posedge vif.clk);
  vif.block_valid <= 1'b0;
  
  // Optional: Send second data 1 word different 
  
  @(posedge vif.clk);
  vif.message_block <= 512'h6aadaf;
  vif.first_word <= 4'h6;
  vif.block_valid <= 1'b1;
  wait(vif.hash_valid);
  @(posedge vif.clk);
  vif.block_valid <= 1'b0; 
  
  /////Sending Third data same as first 
  
  @(posedge vif.clk);
  vif.message_block <= 512'h6aadaf;
  vif.first_word <= 4'h6;
  vif.block_valid <= 1'b1;
  wait(vif.hash_valid);
  @(posedge vif.clk);
  vif.block_valid <= 1'b0; 
endtask 

task run();
reset();
body();
endtask

endclass




class mon; ///////////////////////////monitoring if it is valid or not ;
  virtual sha256 vif;
  bit[255:0] store [1:0];
  int count = 0;

task run();
  // Wait for first valid hash
  wait(vif.hash_valid);
   $display("hash time %0t",$time);
  wait(!vif.block_valid);
  store[0] = vif.hash;
  $display("First hash: %h", vif.hash);
  $display("hash time %0t",$time);
  
  
//   Wait for next valid hash (if you expect multiple)
  wait(vif.hash_valid);
  wait(!vif.block_valid);
  store[1] = vif.hash;
  $display("Second hash: %h", vif.hash);
  
  // Or just monitor continuously
  forever begin
    @(posedge vif.clk);
    if(store[0]==vif.hash) begin
      $display("Data Matched ");
      $display("Hash output: %h", vif.hash);
    end
    else 
      $error("data mismatched ");
    $stop;
  end
endtask
endclass




class envo;
 gen g;
 mon m;
 
 virtual sha256 vif; ///////////////////////creating the virtual interface 
 function new( virtual sha256 vif);
 g=new();
 m=new();
 this.vif=vif;
 g.vif=this.vif;
 m.vif=this.vif;
 endfunction
 task test();
 fork 
 g.run();
 m.run();
 join
 endtask
 
 task run();
 test();
 endtask 

endclass





module testbench();
envo e;

sha256 vif();

  sha256_parallel_pipelined  dut(.clk(vif.clk) , .reset_n(vif.reset_n), .message_block(vif.message_block), .first_word(vif.first_word), .block_valid(vif.block_valid) ,.hash(vif.hash), .hash_valid(vif.hash_valid));



    
    initial begin
    vif.clk=1'b0;
    vif.reset_n=1'b0;
      #60;
      vif.reset_n=1'b1;
    end

always #35 vif.clk=~vif.clk;
  
  initial begin
    e=new(vif);
    e.run();
    #2000;
    $finish();
  end
  
  initial begin
    $dumpfile("Sha.vcd");
    $dumpvars;
  end
  
  


endmodule
