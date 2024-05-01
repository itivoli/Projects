`timescale 1ns / 1ps

// Decoder Module
// Takes a 32-bit instruction as input and drives each
// of the output based on the Instruction Set Architecture
// given in the project instructions
module Decoder(
    input [31:0] instruction,   // 32-bit Instruction to be decomposed into constituent fields.
    output [2:0] opcode,        // Opcode.
    output [4:0] reg0,          // Source register (rs).
    output [4:0] reg1,          // Target or Transfer register (rt).
    output [4:0] reg2,          // Destination register (rd).
    output [15:0] addr          // Address (read or branch).
    );
    
    // Parse the fields to their appropriate outputs.
    assign opcode = instruction[31:29]; // Constant.
    assign reg0 = instruction[28:24];   // Constant.
    assign reg1 = instruction[23:19];   // Present only in Arithemtic and Control instructions. Ignored otherwise.
    assign reg2 = instruction[18:14];   // Present only in Arithmetic instructions. Ignored otherwise.
    assign addr = instruction[15:0];    // Present only in Memory and Control instructions. Ignored otherwise.

endmodule
