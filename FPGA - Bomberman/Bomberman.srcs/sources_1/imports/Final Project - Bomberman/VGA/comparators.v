`timescale 1ns / 1ps

/*
    Comparators Module:
    Module that deals with making the proper comparisons
    with the horizontal and vertical count values and 
    the specifications from the VGA standard to ensure 
    proper RGB output.
*/
module comparators(
    input [9:0] h_count,      // Horizontal pixel count.     
    input [9:0] v_count,      // Vertical pixel count.
    output h_sync,       // Hsync signal.
    output v_sync,       // Vsync signal.
    output active_video // Display active signal.
    );

    // Horizontal Parameters.
    localparam H_DIS_T = 640;                                           // Horizontal display area (pixels).                                                          
    localparam H_PUL_W = 96;                                            // Horizontal pulse width (pixels).   
    localparam H_FRO_POR = 16;                                          // Horizontal front porch (pixels).   
    localparam H_BA_POR = 48;                                           // Horizontal back porch (pixels).   
    localparam H_MAX = H_DIS_T + H_PUL_W + H_FRO_POR + H_BA_POR - 1;    // Horizontal counter max value (pixels).   

    // Vertical Parameters.
    localparam V_DIS_T = 480;                                           // Vertical display area (pixels).                                                          
    localparam V_PUL_W = 2;                                             // Vertical pulse width (pixels).   
    localparam V_FRO_POR = 10;                                          // Vertical front porch (pixels).   
    localparam V_BA_POR = 29;                                           // Vertical back porch (pixels).   
    localparam V_MAX = V_DIS_T + V_PUL_W + V_FRO_POR + V_BA_POR - 1;    // Vertical counter max value (pixels).

    // Drive the outputs.
    assign h_sync = (h_count >= (H_DIS_T + H_FRO_POR)) && (h_count < (H_DIS_T + H_FRO_POR + H_PUL_W));
    assign v_sync = (v_count >= (V_DIS_T + V_BA_POR)) && (v_count < (V_DIS_T + V_BA_POR + V_PUL_W));
    assign active_video = (h_count < H_DIS_T && v_count < V_DIS_T);
    
endmodule
