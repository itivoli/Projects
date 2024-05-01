`timescale 1ns / 1ps

// RegisterFile Module
// A 2-d register array with two read ports
// and one write port.
module  RegisterFile(
    input [15:0] readAddressA,      // 16-bit address of 1st register to read from.
    input [15:0] readAddressB,      // 16-bit address of 2nd register to read from.
    input [15:0] writeAddress,      // 16-bit address of register to write to.
    input writeEn,                  // Write enable.
    input [31:0] writeData,         // 32 -bit data to write to register.
    output [31:0] readDataA,        // 32-bit data read from the 1st register.
    output [31:0] readDataB         // 32-bit data read from the 2nd register.
    );
    
    // 8-KB array to hold registers (32-bits wide, 256 possible entries.)
    reg [31:0] registers [0:15];
    
    // Initialize registers to zero.
    integer i;
    initial begin
        for(i = 0; i < 16; i = i + 1) registers[i] = 32'b0;
    end

    // Read data from the specified register addresses.
    assign readDataA = registers[readAddressA];
    assign readDataB = registers[readAddressB];

    // Write to specified register if needed.
    always @ (writeEn) begin
        if(writeEn) registers[writeAddress] = writeData;
    end
    
endmodule
