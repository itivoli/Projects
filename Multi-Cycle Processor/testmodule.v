`timescale 1ns / 1ps

// This module is for testing purposes only.
module testmodule(
    input [15:0] instrAddy,
    output [31:0] res
    );
    
    // Read instruction memory;
    reg [31:0] instructionMem [0:255];
    initial $readmemb(".\instructions.mem", instructionMem);
    
    // Output first and second entries.
    always @ (res) begin
        $display("Instr @0x%0h: 0x%0h", instrAddy, res);
    end
endmodule
