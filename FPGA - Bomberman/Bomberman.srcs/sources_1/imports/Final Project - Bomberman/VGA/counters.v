`timescale 1ns / 1ps

/*
    Counter Module:
    Module to count through the horizontal/vertical region
    of the 640 x 480 VGA display and monitor the 
    horizontal/vertical timing.
*/
module counters(
    input clk,            
    input rst,
    output reg [9:0] h_count,
    output reg [9:0] v_count
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

    // Horizontal counter.
    always @(posedge clk) begin
        if(rst) h_count <= 0;
        else if(h_count == H_MAX) h_count <= 0;
        else h_count <= h_count + 1;
    end

    // Vertical counter.
    always @(posedge clk) begin
        if(rst) v_count <= 0;
        else begin
            if(h_count == H_MAX) begin
                if(v_count == V_MAX) v_count <= 0;
                else v_count <= v_count + 1;
            end
        end
    end

endmodule
