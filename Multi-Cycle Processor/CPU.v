`timescale 1ns / 1ps

// CPU Module
// Top Module for CPU.
module CPU(input clk); 
     
    reg [15:0]  pc_q = 0;      // Program Counter
    wire [31:0]  instruction_q; // Holds instruction binary 
    reg [3:0]   state_q = 0;   // State of CPU

    // Required inputs for CPU Modules

    // Decoded Instruction.
    wire [4:0] source_q;            // Source Register.
    wire [4:0] target_q;            // Target or Transfer Register.
    wire [4:0] destination_q;       // Destination Register.
    wire [2:0] opcode_q;            // Instruction Opcode
    wire [15:0] address_q;          // Address to store/load a word to/from. Used only w/ lw and sw.
    
    // RegisterFile inputs and outputs.
    reg [31:0] regWriteData_q;      // Data to write to registers.
    reg [15:0] regWriteAddress_q;   // Register address to write to.
    wire [31:0] dataReadRegA_q;     // Read result from first register.
    wire [31:0] dataReadRegB_q;     // Read result from second register.
    reg regWriteEn_q = 0;           // Write Enable signal (to registers).

    // DataMemory Module inputs/outpus
    reg [31:0] MemWriteData_q;      // Data to write to memory.
    wire [31:0] dataReadMem_q;      // Read result from second register.
    reg memWriteEn_q = 0;           // Write Enable signal (to memory).
    
    reg [15:0] instrMemAddress;     // Instruction Memory specific address. 
    wire [31:0] ALUResult_q;        // Data to write to registers/memory
    wire update_pc;
    
    // Instantiate Decoder.
    Decoder instructionDecoder (
        .instruction(instruction_q), 
        .opcode(opcode_q), 
        .reg0(source_q), 
        .reg1(target_q), 
        .reg2(destination_q), 
        .addr(address_q)
    );
    
    // Instantiate Register File.
    RegisterFile registers (
        .readAddressA({11'b0, source_q}),
        .readAddressB({11'b0, target_q}),
        .writeAddress(regWriteAddress_q),
        .writeEn(regWriteEn_q),
        .writeData(regWriteData_q),
        .readDataA(dataReadRegA_q),
        .readDataB(dataReadRegB_q)
    );

    // Instantiate Instruction Memory.
    InstructionMemory instructionMemory (
        .inst_address(instrMemAddress),
        .read_data(instruction_q)
    );

    // Instantiate Data Memory.
    DataMemory dataMemory (
        .data_address(address_q),
        .write_en(memWriteEn_q),
        .write_data(MemWriteData_q),
        .read_data(dataReadMem_q)
    );

    // Instantiate ALU.
    ALU cpuALU (
        .inputA(dataReadRegA_q),
        .inputB(dataReadRegB_q),
        .opcode(opcode_q),
        .result(ALUResult_q),
        .updatePC(update_pc)
    );

    // Instruction Mnemonics and special instructions.
    parameter LW = 0, SW = 1, BEQ = 2, BLT = 3, ADD = 4, SUB = 5, AND = 6, OR = 7;
    parameter kill = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
    parameter nop = 32'b0;

    // Normal CPU functioning.
    always @ (posedge clk) begin
        
        // Instruction Fetch. Read instruction from instruction memory.
        if(state_q == 0) begin         

            // Load the the address of the next instruction.
            if (update_pc == 1) begin 
                instrMemAddress <= address_q;
                pc_q <= address_q + 1;
            end
            else begin
                instrMemAddress <= pc_q;
                pc_q <= pc_q + 1;
            end

            // Update state and clear Memory Write Enable if needed.
            memWriteEn_q <= 0;
            state_q <= 1;
        end 

        // Instruction Decode. Decode instruction into their consitituent pieces and specify some control.
        else if(state_q == 1) begin     
            
            // Transfer instruction specific information.
            case(opcode_q) 
                LW: begin
                        regWriteAddress_q <= {11'b0, source_q}; // Specify the address as a register address.
                        regWriteData_q <= dataReadMem_q;        // Load the data loaded from Memory to store in registers.
                    end

                SW: begin
                        MemWriteData_q <= dataReadRegA_q;   // Load data read from source register to be stored in memory.
                    end 

                ADD, SUB, AND, OR: begin
                        regWriteAddress_q <= {11'b0, destination_q};    // Specify the address to write to as the destination register.
                        regWriteData_q <= ALUResult_q;                  // Specicify ALU result as date to be written to destination register.
                    end
            endcase
            
            // Update state (or stop computation if kill instruction is read.)
            if(instruction_q == kill) state_q = -1;
            //else if(instruction_q == kill) state_q = -1;
            else state_q = 2;
        end 

        // Execute Stage. Perform ALU operations and/or pull data from registers/memory.
        else if(state_q == 2) begin          

            // Enable regWrite if Arithmetic instruction or if lw. 
            regWriteEn_q <= (opcode_q[2] == 1 || opcode_q[2:0] == 3'b000) ? 1 : 0 ;

            // Update state.
            state_q <= 3; 
        end 
        
        // Memory Stage. Access Memory and register file (for load).
        else if(state_q == 3) begin  

            // Enable memWrite if store word instruction. Disable regWrite if needed.
            memWriteEn_q <= (opcode_q[2:0] == 3'b001) ? 1: 0;
            regWriteEn_q <= 0;
                        
            // Update state.
            state_q <= 0;
        end  

    end
    
endmodule
