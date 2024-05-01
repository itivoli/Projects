`timescale 1ns / 1ps

// Testbench for the Instruction Memory Module.
module INSTR_MEM_SIM();
    
    // Define Instruction Memory address i/o.
    reg [15:0] inst_address_tb;     // 16-bit Address of instruction being read from memory.
    wire [31:0] read_data_tb;       // 32-bit Instruction located at specified address.   
    
    // Instantiate InstructionMemory Module.
    InstructionMemory InstructionMemory_tb (
        .inst_address(inst_address_tb),
        .read_data(read_data_tb)
    );

    // Create array of preloaded instructions, load control signals.
    reg matched = 0;
    reg [31:0] instruction_tb;
    integer i;

    // Bgin test;
    initial begin
        for(i = 0; i < 4; i = i + 1) begin
            // Set the instruction address and test instruction.
            inst_address_tb = i;
            case (i)
                // Test Memory instruction.
                0:  instruction_tb = 32'b000_00000_00000000_0000000000000010;     

                // Test Control instruction.
                1: instruction_tb = 32'b010_00010_00000_000_0000000000001101;

                // Test Arithemetic instruction.
                2: instruction_tb = 32'b100_00000_00001_00010_00000000000000;

                // Test Nop instruction.
                3: instruction_tb = 32'b0;
            endcase

            // Compare what is read with what is expected.
            #50;
            matched = (read_data_tb == instruction_tb) ? 1 : 0;
            
            // Reset signals.
            #50;
            instruction_tb = 0;
            matched = 0;
        end
    end    
    
endmodule
