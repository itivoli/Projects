`timescale 1ns / 1ps

// Testbench for the ALU Module
module ALU_SIM();
    
    // Define ALU i/o.
    reg [2:0] opcode_tb;       // Opcode for instruction being evaluated.
    reg [31:0] inputA_tb;      // 1st data input for computations.
    reg [31:0] inputB_tb;      // 2nd data input for computations.
    wire [31:0] result_tb;      // Result of Arithmetic instruction computations.
    wire updatePC_tb;           // Flag for control instructions.
    
    // Instantiate ALU Module.
    ALU ALU_TB(
        .opcode(opcode_tb),
        .inputA(inputA_tb),
        .inputB(inputB_tb),
        .result(result_tb),
        .updatePC(updatePC_tb)
    );
    
    // Instruction Mnemonics for readibility.
    parameter BEQ = 2, BLT = 3, ADD = 4, SUB = 5, AND = 6, OR = 7;

    // Initialize signals and begin test.
    integer i = 0;
    initial begin
        for(i = 2; i < 8; i = i + 1) begin
        
            // Set the opcode and load the test case.
            opcode_tb = i;
            case(i) 
                // Test the BEQ instruction.
                BEQ:begin
                    // Set unequal inputs. 
                    inputA_tb = 4;
                    inputB_tb = 5;
                    #40;
                    
                    // Set equal inputs.
                    inputA_tb = 6;
                    inputB_tb = 6;
                    #40;
                end
                    
                // Test the BLT instruction.
                BLT:begin
                    // Set equal inputs. 
                    inputA_tb = 4;
                    inputB_tb = 4;
                    #40;
                    
                    // Set inputA > inputB.
                    inputA_tb = 6;
                    inputB_tb = 5;
                    #40;
                    
                    // Set inputA < inputB.
                    inputA_tb = 5;
                    inputB_tb = 6;
                    #40;
                end
                    
                // Test the ADD instruction.    
                ADD:begin
                    // Set inputs. 
                    inputA_tb = 4;
                    inputB_tb = 2;
                    #40;
                    
                    // Set inputs.
                    inputA_tb = 2;
                    inputB_tb = 4;
                    #40;
                end
                    
                // Test the SUB instruction. 
                SUB:begin
                    // Set inputs. 
                    inputA_tb = 9;
                    inputB_tb = 5;
                    #40;
                    
                    // Set inputs.
                    inputA_tb = 5;
                    inputB_tb = 9;
                    #40;
                end
                                    
                // Test the AND instruction. 
                AND:begin
                    // Set inputs. 
                    inputA_tb = 32'b0000;
                    inputB_tb = 32'b1111;
                    #40;
                    
                    // Set inputs.
                    inputA_tb = 32'b1010;
                    inputB_tb = 32'b1100;
                    #40;
                end
                    
                // Test the OR instruction.    
                OR: begin 
                    // Set inputs. 
                    inputA_tb = 32'b0000;
                    inputB_tb = 32'b1111;
                    #40;
                    
                    // Set inputs.
                    inputA_tb = 32'b1010;
                    inputB_tb = 32'b1100;
                    #40;
                end
            
            endcase
        end
    end
    
endmodule
