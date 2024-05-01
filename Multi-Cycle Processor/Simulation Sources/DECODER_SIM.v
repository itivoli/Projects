`timescale 1ns / 1ps

// Testbench for the Decoder Module
module DECODER_SIM();

    // Define Decoder i/o.
    reg [31:0] instruction_tb;  // 32-bit Instruction to be decomposed into constituent fields.
    wire [2:0] opcode_tb;       // Opcode for instruction being evaluated.
    wire [4:0] reg0_tb;         // Source register (rs).
    wire [4:0] reg1_tb;         // Target or Transfer register (rt).
    wire [4:0] reg2_tb;         // Destination register (rd).
    wire [15:0] addr_tb;        // Address (read or branch).

    // Instantiate Decoder Module.
    Decoder Decoder_tb (
        .instruction(instruction_tb),
        .opcode(opcode_tb),
        .reg0(reg0_tb),
        .reg1(reg1_tb),
        .reg2(reg2_tb),
        .addr(addr_tb)
    );
    
    // Opcode Mnemonics for readibility.
    parameter LW = 0, SW = 1, BEQ = 2, BLT = 3, ADD = 4, SUB = 5, AND = 6, OR = 7;

    // Initialize control variable.
    integer i = 0;

    // Begin test.
    initial begin
        for(i = 0; i < 8; i = i + 1) begin

            // Set the rest of the test case.
            case(i) 

                // Test the Memory instructions.
                LW, SW: begin
                    // Set instruction, delay for 40 nanoseconds.
                    instruction_tb = {i, 5'd4, 8'd0, 16'd7};
                    #40;
                end

                // Test the control instructions.
                BEQ, BLT: begin 
                    // Set instruction, delay for 40 nanoseconds.
                    instruction_tb = {i, 5'd2, 5'd6, 3'd3, 16'd6};
                    #40;
                end

                // Test the Arithmetic instructions.
                ADD, SUB, AND, OR: begin    
                    // Set instruction, delay for 40 nanoseconds.
                    instruction_tb = {i, 5'd3, 5'd5, 5'd7, 14'd0};
                    #40;  
                end
                
            endcase
        end
    end
endmodule
