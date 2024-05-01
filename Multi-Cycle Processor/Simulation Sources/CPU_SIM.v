`timescale 1ns / 1ps

module CPU_SIM();

    // Inputs.
    reg clk;
    
    // Instantiate CPU.
    CPU simulatedCPU(.clk(clk));
    
    // Initialize the clock.
    parameter half_cycle = 50;
    initial begin: clock_tick
        clk = 0;
        forever #half_cycle clk = clk ^ 1;
    end
    
endmodule
