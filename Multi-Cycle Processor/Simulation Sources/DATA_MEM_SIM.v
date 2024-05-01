`timescale 1ns / 1ps

// Testbench for the DataMemory Module
module DATA_MEM_SIM();

    // Define Data Memory address i/o.
    reg [15:0] data_address_tb;     // 16-bit address of data to be accessed within memory.
    reg write_en_tb;                // Write enable signal.
    reg [31:0] write_data_tb;       // 32-bit data to be written to the specified address.
    wire [31:0] read_data_tb;       // 32-bit data read from the specified address.
    
    // Instantiate DataMemory Module.
    DataMemory DataMemory_tb (
        .data_address(data_address_tb),
        .write_en(write_en_tb),
        .write_data(write_data_tb),
        .read_data(read_data_tb)
    );

    // Initialize observation and control variables.
    reg read_match = 0;
    reg [31:0] test_data_tb;
    integer i;

    // Begin testing.
    initial begin
        // Initialize inputs.
        data_address_tb = 0;
        write_en_tb = 0;
        write_data_tb = 0;
        
        // Manipulate the memory.
        assign read_match = (read_data_tb == test_data_tb) ? 1 : 0;
        for(i = 0; i < 10; i = i + 1) begin
            // Set initial comparison point.
            data_address_tb = i;
            test_data_tb = i;

            // Write to address and update comparison point.
            #10;
            write_en_tb = 1;
            write_data_tb = 5 + read_data_tb;
            test_data_tb = 5 + read_data_tb;

            // Disable write.
            #10;
            write_en_tb = 0;
        end
    end  
endmodule
