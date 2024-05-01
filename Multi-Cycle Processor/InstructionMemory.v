`timescale 1ns / 1ps

// Instruction Module. 
// A 2-d register array with one read port.
module InstructionMemory(
    input [15:0] inst_address,      // 16-bit Address of instruction being read from memory.
    output [31:0] read_data         // 32-bit Instruction located at specified address.       
    );

    // 8-KB array to hold instructions (32-bits wide, 256 possible entries.)
    reg [31:0] instructionMem [0:255];

    // Initialize Instructions in the memory for testing.
    initial $readmemb("C:/Users/XxElv/OneDrive - University of Central Florida/Fall 2023 - Spring 2024/Spring/HDL in Digital Systems Design/Final Project/Implemented/Verilog-CPU/CPU/CPU.srcs/sources_1/new/instructions.mem", instructionMem);
    
    // Read the instructions from the given address.
    assign read_data = instructionMem[{16'd0, inst_address}];
        
endmodule