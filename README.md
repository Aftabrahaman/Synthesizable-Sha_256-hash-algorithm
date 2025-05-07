## SHA-256 Parallel Pipelined Module Documentation
### 1. Overview
This document describes a high-performance SHA-256 cryptographic hash module implemented in System Verilog. The design features:
•	10-cycle latency pipeline architecture
•	7-rounds-per-cycle parallel processing
•	Fully synchronous design with active-low reset
•	Compliant with FIPS 180-4 SHA-256 standard
### 3. Core Components

## 3.1 Cryptographic Constants
•	K[0:63]: Round constants derived from cube roots of primes
•	H0[0:7]: Initial hash values from square roots of primes
![image](https://github.com/user-attachments/assets/04800c1e-c8a4-453a-b2ad-2378bc20c68e)


## 3.3. Padding 1 ,0’s and length of the input message 

 ![image](https://github.com/user-attachments/assets/2a3526ef-766c-4629-9830-f065b6f765f5)


We take [511:0] as an input  “message_block”. To pad 1 and zeros after it we need to find the length of input message . 

“padding_m” module prepares a 512-bit message block for SHA-256 hashing by applying the standard padding scheme. It takes a raw 512-bit input message (m) and its actual bit length (siz), then outputs a padded block (pm) that includes:
	The original message bits (truncated to siz bits),
	A single ‘1’ bit appended immediately after the message,
	Enough ‘0’ bits to fill the block (except the last 64 bits),
	The original message length (in bits) stored in the last 64 bits (big-endian format).
How It Works
	Bitmasking: The module first isolates the valid message bits using a dynamic bitmask (message & ((1 << bit_length) - 1)), ensuring only the first siz bits are preserved.
	‘1’ Bit Injection: A 1 is placed at the position bit_length to mark the end of the message (per SHA-256 standards).
	Length Encoding: The message length (in bits) is written into the final 64 bits of the block, allowing the hash algorithm to process variable-length inputs.

 			
 	 		![image](https://github.com/user-attachments/assets/0b668640-05dd-43df-a4a9-fe9752a7c2b9)

 		
 			
