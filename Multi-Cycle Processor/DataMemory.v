`timescale 1ns / 1ps

// DataMemory Module
// A 2-d register array with one read port
// and one write port
module  DataMemory(
    input [15:0] data_address,      // 16-bit address of data to be accessed within memory.
    input write_en,                 // Write enable signal.
    input [31:0] write_data,        // 32-bit data to be written to the specified address.
    output [31:0] read_data         // 32-bit data read from the specified address.
    );

    // 8-KB array to hold data (32-bits wide, 256 possible entries.)
    reg [31:0] dataMem [0:255];
    
    // Initialize each block in the array to its block number.
    integer i;
    initial begin
        for(i = 0; i < 256; i = i + 1) dataMem[i] = i;
        $writememb("C:/Users/XxElv/OneDrive - University of Central Florida/Fall 2023 - Spring 2024/Spring/HDL in Digital Systems Design/Final Project/Implemented/Verilog-CPU/CPU/CPU.srcs/sources_1/new/data.mem", dataMem);
    end
    
    // Read the data specifed by the address.
    assign read_data = dataMem[{16'd0, data_address}];
    
    // Write data to the block specified by the address.
    always @* begin
        if(write_en) begin
            dataMem[{16'd0, data_address}] = write_data;
            $writememb("C:/Users/XxElv/OneDrive - University of Central Florida/Fall 2023 - Spring 2024/Spring/HDL in Digital Systems Design/Final Project/Implemented/Verilog-CPU/CPU/CPU.srcs/sources_1/new/data.mem", dataMem);
        end
    end
    
endmodule
