`timescale 1ns / 1ps

/*
    VGA Controller Module: 
    Module that controls input and 
    provides output to VGA port
    on the Basys 3 board for display
    on a VGA monitor.
*/
module vgaController(
    input clk,              // Clock driving display.
    input rst,              // Reset switch.
    output hsync,           // Hsync signal.
    output vsync,           // Vertical signal.
    output [9:0] x_pos,     // Horizontal position of the cursor.
    output [9:0] y_pos,     // Vertical position of the cursor.
    output pclk,            // Pixel clock.
    output video_on         // Signals if cursor is in active region of VGA Display.
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
        .rst(rst), 
        .h_count(hcount), 
        .v_count(vcount)
        );

    // Comparators.
    wire display_on;
    comparators vga_comparators(
        .h_count(hcount), 
        .v_count(vcount), 
        .h_sync(hsync), 
        .v_sync(vsync), 
        .active_video(display_on)
        );

    // Assign outputs.
    assign x_pos = hcount;
    assign y_pos = vcount;
    assign pclk = p_clk;
    assign video_on = display_on;
    
endmodule
