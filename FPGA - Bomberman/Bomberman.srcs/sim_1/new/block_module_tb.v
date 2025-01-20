`timescale 1ns / 1ps

module block_module_tb();

// Inputs
reg clk;
reg reset;
reg display_on;
reg [9:0] x, y, x_a, y_a;
reg [1:0] cd;
reg [9:0] x_b, y_b;
reg [9:0] waddr;
reg we;

// Outputs
wire [11:0] rgb_out;
wire block_on;
wire bm_blocked;
wire block_is_powerup;

// Instantiate the Unit Under Test (UUT)
block_module uut (
    .clk(clk),
    .reset(reset),
    .display_on(display_on),
    .x(x),
    .y(y),
    .x_a(x_a),
    .y_a(y_a),
    .cd(cd),
    .x_b(x_b),
    .y_b(y_b),
    .waddr(waddr),
    .we(we),
    .rgb_out(rgb_out),
    .block_on(block_on),
    .bm_blocked(bm_blocked),
    .block_is_powerup(block_is_powerup)
);

// Clock generation
always #5 clk = ~clk;

// Testbench stimulus
initial begin
    // Initialize inputs
    clk = 0;
    reset = 1;
    display_on = 0;
    x = 0;
    y = 0;
    x_a = 0;
    y_a = 0;
    cd = 2'b00;
    x_b = 0;
    y_b = 0;
    waddr = 0;
    we = 0;

    // Wait for global reset
    #20;
    reset = 0;

    // Test 1: No display, reset active
    #10;
    display_on = 0;
    x = 50;
    y = 40;

    // Test 2: Display active and coordinates within range
    #10;
    display_on = 1;
    x_a = 100;
    y_a = 100;

    // Test 3: Write enable and valid address
    #10;
    we = 1;
    waddr = 10;
    
    // Test 4: Simulate movement with bomberman blocked
    #10;
    we = 0;
    cd = 2'b01; // Move right
    x_b = 60;
    y_b = 50;

    // Test 5: Simulate power-up detection
    #10;
    cd = 2'b10; // Move down
    x_b = 200;
    y_b = 150;

    // Test 6: Observe LED behavior
    #10;
    display_on = 0;
    x = 300;
    y = 200;

    // End simulation
    #50;
    $stop;
end

// Monitor outputs
initial begin
    $monitor("Time: %t | block_on: %b | bm_blocked: %b | block_is_powerup: %b | rgb_out: %h | led: %h",
             $time, block_on, bm_blocked, block_is_powerup, rgb_out, led);
end

endmodule
