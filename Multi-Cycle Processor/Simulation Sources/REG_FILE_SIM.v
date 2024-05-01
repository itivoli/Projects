`timescale 1ns / 1ps


// Testbench for the RegisterFile Module
module REG_FILE_SIM();
    // Define RegisterFile i/o.
    reg [15:0] readAddressA_tb;         // 16-bit Address of first read register.
    reg [15:0] readAddressB_tb;         // 16-bit Address of second read register.
    reg [15:0] writeAddress_tb;         // 16-bit Address of write register.
    reg writeEn_tb;                     // Write enable signal.
    reg [31:0] writeData_tb;            // 32-bit data to place in write register.
    wire [31:0] readDataA_tb;           // 32-bit data read from first register.   
    wire [31:0] readDataB_tb;           // 32-bit data read from second register.   
    
    // Instantiate RegisterFile Module.
    RegisterFile registers_tb (
        .readAddressA(readAddressA_tb),
        .readAddressB(readAddressB_tb),
        .writeAddress(writeAddress_tb),
        .writeEn(writeEn_tb),
        .writeData(writeData_tb),
        .readDataA(readDataA_tb),
        .readDataB(readDataB_tb)
    );

    // Write to first 5 registers.
    integer i = 0;
    initial begin

        // Set initial addresses.
        readAddressA_tb = 0;
        readAddressB_tb = 1;
        writeAddress_tb = 0;
        writeEn_tb = 0;
        writeData_tb = 0;

        // Manipulate the registers.
        while(i < 5) begin

            // Write to register A.
            #10
            writeAddress_tb = readAddressA_tb;
            writeEn_tb = 1;
            writeData_tb = 2 + writeAddress_tb;
            #5;  
            writeEn_tb = 0;

            // Write to register B.
            #10
            writeAddress_tb = readAddressB_tb;
            writeEn_tb = 1;
            writeData_tb = 2 + writeAddress_tb;
            #5;  
            writeEn_tb = 0;

            // Set read addresses and increment loop.
            #15
            readAddressA_tb = readAddressA_tb + 2;
            readAddressB_tb = readAddressB_tb + 2;
            i = i + 1;
        end
    end   
endmodule
