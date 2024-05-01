`timescale 1ns / 1ps

// ALU Module
// Performs arithmetic operations for add,
// sub, and, or operations. Also performs 
// comparison operation for beq, blt.
module ALU(
    input [2:0] opcode,         // Opcode for instruction being evaluated.
    input [31:0] inputA,        // 1st data input for computations.
    input [31:0] inputB,        // 2nd data input for computations.
    output [31:0] result,       // Result of Arithmetic instruction computations.
    output updatePC             // Flag for control instructions.
    );
    
    // Instruction Mnemonics for readibility.
    parameter BEQ = 2, BLT = 3, ADD = 4, SUB = 5, AND = 6, OR = 7;

    // Handle Control Instruction Logic.
    assign updatePC = opcode == BEQ ? (inputA == inputB) : (
                        opcode == BLT ? (inputA < inputB) : 0 );
    
    // Handle Arithmetic Instruction Logic.
    assign result = opcode == ADD ? (inputA + inputB) : (
                        opcode == SUB ? (inputB - inputA) : (
                            opcode == AND ? (inputA & inputB) : (
                                opcode == OR ? (inputA | inputB) : 0
                            )
                        )
                    );     
        
endmodule
