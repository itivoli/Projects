`timescale 1ns / 1ps



module LFSR_TEST();

// Inputs
    reg clk;
    reg rst;
    reg w_en;
    reg [15:0] w_in;

    // Outputs
    wire [15:0] out;

    // Instantiate the Unit Under Test (UUT)
    LFSR_16 uut (
        .clk(clk),
        .rst(rst),
        .w_en(w_en),
        .w_in(w_in),
        .out(out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 ns clock period
    end

    // Stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        w_en = 0;
        w_in = 0;

        // Monitor outputs
        $monitor("Time: %0t | rst: %b | w_en: %b | w_in: %h | out: %h", $time, rst, w_en, w_in, out);

        // Apply reset
        #10 rst = 0;

        // Observe normal shifting
        #10;
        repeat (5) @(posedge clk);

        // Write a specific value to the LFSR
        w_en = 1;
        w_in = 16'hDEAD;
        @(posedge clk);
        w_en = 0;

        // Observe shifts from written value
        repeat (5) @(posedge clk);

        // Reset again
        rst = 1;
        @(posedge clk);
        rst = 0;

        // Observe shifts after reset
        repeat (5) @(posedge clk);

        // End simulation
        $finish;
    end
    
endmodule
