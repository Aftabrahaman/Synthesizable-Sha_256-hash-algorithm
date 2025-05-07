module sha256_parallel_pipelined (
    input logic clk,
    input logic reset_n,
    input logic [511:0] message_block, 
    input logic [3:0] last_word,
    input logic block_valid,
    output logic [255:0] hash,
    output logic hash_valid
);

// SHA-256 constants (first 32 bits of fractional parts of cube roots of first 64 primes)
localparam logic [31:0] K[0:63] = '{
    32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
    32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
    32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
    32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
    32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
    32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
    32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
    32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
   }; 

// Initial hash values
localparam logic [31:0] H0[0:7] = '{
    32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};


  

// SHA-256 functions
function logic [31:0] ch(input logic [31:0] x, y, z);
    ch = (x & y) ^ (~x & z);
endfunction

function logic [31:0] maj(input logic [31:0] x, y, z);
    maj = (x & y) ^ (x & z) ^ (y & z);
endfunction

function logic [31:0] sigma0(input logic [31:0] x);
    sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
endfunction

function logic [31:0] sigma1(input logic [31:0] x);
    sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
endfunction

function logic [31:0] SIGMA0(input logic [31:0] x);
    SIGMA0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
endfunction

function logic [31:0] SIGMA1(input logic [31:0] x);
    SIGMA1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
endfunction

// Pipeline registers
typedef struct packed {
    logic [31:0] a, b, c, d, e, f, g, h;
    logic [31:0][6:0] w;  // Store 7 words per cycle
    logic [3:0] cycle_count;
    logic valid;
} stage_reg_t;

stage_reg_t stage_reg;
logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
logic hash_valid_reg;

// Control signals
logic processing;
logic [3:0] cycle_counter;

/////////////// register to store the input message  in byte form
logic  [127:0][3:0] data_in;
int unsigned  size;
logic [511:0] padded ;
////////converting bit to byte and store it to  register  /////////////////////////

bit_to_byte dut2(.message_input(message_block),.data_out(data_in));

////////finding the last bit /////////////////////////
find_length dut(.mess(data_in),.last_word(last_word),.size(size));

/////////////////////////////padding message ///////////////////////////////

padding_m dut3(.m(message_block),.siz(size),.pm(padded));

//logic [511:0] padded;
//logic [31:0][6:0] expanded_words;

//logic [511:0] padded = pad_message(message_block,size);
//logic [31:0][6:0] expanded_words = expand_message_7(padded, cycle);
// Message expansion for 7 rounds per cycle
function logic [6:0] [31:0] expand_message_7(input logic [511:0] block, input logic [3:0] cycle);
    logic [31:0] w[0:63];
    logic[6:0] [31:0] w_out;
    
    // Initialize first 16 words
    for (int i = 0; i < 16; i++) begin
        w[i] = block[32*i +: 32];
    end
    
    // Expand remaining words
    for (int t = 16; t < 64; t++) begin
        w[t] = sigma1(w[t-2]) + w[t-7] + sigma0(w[t-15]) + w[t-16];
    end
    
    // Select 7 words for current cycle
    for (int i = 0; i < 7; i++) begin
        automatic int t = cycle*7 + i;
        w_out[i] = (t < 64) ? w[t] : 32'h0;
    end
    
    return w_out;
endfunction





// Main processing pipeline (10-cycle implementation)
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        stage_reg <= '{default:0};
        cycle_counter <= 0;
        processing <= 0;
        hash_valid_reg <= 0;
        {h0,h1,h2,h3,h4,h5,h6,h7} <= '{default:0};
//        data_in<='{default:0};
    end else begin
        hash_valid_reg <= 0;
        
        if (block_valid && !processing) begin
            // Initialize processing (Cycle 0)
            stage_reg.a <= H0[0];
            stage_reg.b <= H0[1];
            stage_reg.c <= H0[2];
            stage_reg.d <= H0[3];
            stage_reg.e <= H0[4];
            stage_reg.f <= H0[5];
            stage_reg.g <= H0[6];
            stage_reg.h <= H0[7];
            stage_reg.cycle_count <= 0;
            stage_reg.valid <= 1;
            cycle_counter <= 1;
            processing <= 1;
            
            // Pre-expand message words for first cycle
            stage_reg.w <= expand_message_7(padded, 0);
        end else if (processing) begin
            // Process 7 rounds per cycle (Cycles 1-9)
            for (int i = 0; i < 7; i++) begin
                automatic logic [31:0] t1, t2;
                
                if (i == 0) begin
                    // First round of this cycle
                    t1 = stage_reg.h + SIGMA1(stage_reg.e) + 
                         ch(stage_reg.e, stage_reg.f, stage_reg.g) + 
                         K[stage_reg.cycle_count*7 + i] + stage_reg.w[i];
                    t2 = SIGMA0(stage_reg.a) + maj(stage_reg.a, stage_reg.b, stage_reg.c);
                    
                    stage_reg.a <= t1 + t2;
                    stage_reg.b <= stage_reg.a;
                    stage_reg.c <= stage_reg.b;
                    stage_reg.d <= stage_reg.c;
                    stage_reg.e <= stage_reg.d + t1;
                    stage_reg.f <= stage_reg.e;
                    stage_reg.g <= stage_reg.f;
                    stage_reg.h <= stage_reg.g;
                end else begin
                    // Subsequent rounds use previous results
                    t1 = stage_reg.h + SIGMA1(stage_reg.e) + 
                         ch(stage_reg.e, stage_reg.f, stage_reg.g) + 
                         K[stage_reg.cycle_count*7 + i] + stage_reg.w[i];
                    t2 = SIGMA0(stage_reg.a) + maj(stage_reg.a, stage_reg.b, stage_reg.c);
                    
                    stage_reg.a <= t1 + t2;
                    stage_reg.e <= stage_reg.d + t1;
                end
            end
            
            stage_reg.cycle_count <= stage_reg.cycle_count + 1;
            cycle_counter <= cycle_counter + 1;
            
            if (stage_reg.cycle_count < 9) begin
                // Load next set of message words (Cycles 1-8)
                stage_reg.w <= expand_message_7(padded, stage_reg.cycle_count + 1);
            end else begin
                // Final cycle (Cycle 9) - update hash state
                h0 <= H0[0] + stage_reg.a;
                h1 <= H0[1] + stage_reg.b;
                h2 <= H0[2] + stage_reg.c;
                h3 <= H0[3] + stage_reg.d;
                h4 <= H0[4] + stage_reg.e;
                h5 <= H0[5] + stage_reg.f;
                h6 <= H0[6] + stage_reg.g;
                h7 <= H0[7] + stage_reg.h;
                
                hash_valid_reg <= 1;
                processing <= 0;
            end
        end
    end
end

// Output assignment
assign hash = {h0, h1, h2, h3, h4, h5, h6, h7};
assign hash_valid = hash_valid_reg;

endmodule