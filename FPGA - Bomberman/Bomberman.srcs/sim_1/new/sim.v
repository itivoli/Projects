`timescale 1ns / 1ps

module sim();

    // Testbench signals
    reg clk;
    reg rst;
    reg PB_ENTER, PB_UP, PB_DOWN, PB_LEFT, PB_RIGHT;
    wire hsync, vsync;
    wire [11:0] rgb;

    // Instantiate the top module
    top_module uut (
        .clk(clk),
        .rst(rst),
        .PB_ENTER(PB_ENTER),
        .PB_UP(PB_UP),
        .PB_DOWN(PB_DOWN),
        .PB_LEFT(PB_LEFT),
        .PB_RIGHT(PB_RIGHT),
        .hsync(hsync),
        .vsync(vsync),
        .rgb(rgb)
    );

    // Clock generation (10 ns period -> 100 MHz)
    always begin
        #5 clk = ~clk;  // Toggle every 5ns (100MHz clock)
    end

    // Initial block to initialize signals and apply stimulus
    initial begin
        // Initialize clock and reset
        clk = 0;
        rst = 0;
        PB_ENTER = 0;
        PB_UP = 0;
        PB_DOWN = 0;
        PB_LEFT = 0;
        PB_RIGHT = 0;

        // Apply reset
        rst = 1;
        #100;
        rst = 0;

    end
    
    localparam ONE_MS = 1_000_000;      // 1 ms
    localparam HOLD_DUR = 15 * ONE_MS;     // 15 ms

    initial begin
        
        // Test sequence
        //forever begin    
            
            // Left.
            PB_LEFT = 1;
            #HOLD_DUR;  
            PB_RIGHT = 0;
            #ONE_MS;

            // Left.
            PB_LEFT = 1;
            #HOLD_DUR;  
            PB_RIGHT = 0;
            #ONE_MS;

            PB_DOWN = 1;            // SERIES OF DOWNS.
            #HOLD_DUR;  
            PB_ENTER = 0;
            #ONE_MS;
            
            PB_DOWN = 1;
            #HOLD_DUR;  
            PB_ENTER = 0;
            #ONE_MS;

            PB_DOWN = 1;
            #HOLD_DUR;  
            PB_ENTER = 0;
            #ONE_MS;

            PB_ENTER = 1;               // ENTER
            #HOLD_DUR;  
            PB_ENTER = 0;
            #ONE_MS;

            // First, simulate pressing Right.
            /*PB_RIGHT = 1;
            #HOLD_DUR;  
            PB_RIGHT = 0;
            #ONE_MS;*/

            // First, simulate pressing Right.
            /*PB_RIGHT = 1;
            #HOLD_DUR;  
            PB_RIGHT = 0;
            #ONE_MS;*/;

            // First, simulate pressing Right.
            /*PB_RIGHT = 1;
            #HOLD_DUR;  
            PB_RIGHT = 0;
            #ONE_MS;*/

            // Simulate pressing ENTER
            /*PB_ENTER = 1;
            #HOLD_DUR;  
            PB_ENTER = 0;
            #100;*/

            // First, simulate pressing Right.
            /*PB_RIGHT = 1;
            #HOLD_DUR;  
            PB_RIGHT = 0;
            #100;*/;

            // Simulate pressing ENTER
            /*PB_ENTER = 1;
            #HOLD_DUR;  
            PB_ENTER = 0;
            #100;*/

            // First, simulate pressing Right.
            /*PB_RIGHT = 1;
            #HOLD_DUR;  
            PB_RIGHT = 0;
            #100;*/

            // Simulate pressing ENTER
            /*PB_ENTER = 1;
            #HOLD_DUR;  
            PB_ENTER = 0;
            #100;*/
            $finish;
            // for bomb and explosion
            #(220*ONE_MS);
            #(120*ONE_MS);
            #(10*ONE_MS);
            
        //end
    end
    
endmodule
