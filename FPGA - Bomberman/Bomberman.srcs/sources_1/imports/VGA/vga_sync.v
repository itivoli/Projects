
/*
    VGA Sync Module: 
    Module that controls input and 
    provides output to VGA port
    on the Basys 3 board for display
    on a VGA monitor.
*/
module vga_sync(
    input clk,              // Clock driving display.
    input reset,            // Reset switch.
    output hsync,           // Hsync signal.
    output vsync,           // Vertical signal.
    output display_on,      // Signals if cursor is in active region of VGA Display.
    output p_tick,          // Pixel clock.
    output [9:0] x,         // Horizontal position of the cursor.
    output [9:0] y          // Vertical position of the cursor.
    );

    // Pixel clock divider.
    wire p_clk;
    pixelClockDivider pixel_clock (
        .clk(clk), 
        .pixel_clk(p_clk)
        );

    // Counters.
    wire [9:0] hcount, vcount;
    counters H_and_V_counters(
        .clk(p_clk), 
        .rst(reset), 
        .h_count(hcount), 
        .v_count(vcount)
        );

    // Comparators.
    wire active;
    comparators vga_comparators(
        .h_count(hcount), 
        .v_count(vcount), 
        .h_sync(hsync), 
        .v_sync(vsync), 
        .active_video(active)
        );

    // Assign outputs.
    assign x = hcount;
    assign y = vcount;
    assign p_tick = p_clk;
    assign display_on = active;
    
endmodule
