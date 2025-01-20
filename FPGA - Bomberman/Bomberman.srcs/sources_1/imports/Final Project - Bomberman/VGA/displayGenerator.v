`timescale 1ns / 1ps

/*
    Display Generator Module: 
    Module that dictates the output to a
    VGA Monitor.
*/
module displayGenerator(
    input display_on,           // Signal detailing if display should be written to.
    input pixel_clk,            // VGA Pixel Clock.
    input [9:0] x_pos,          // Horizontal position of the VGA cursor.   
    input [9:0] y_pos,          // Vertical position of the VGA cursor.
    input [23:0] char_data,     // Data of character to display.
    output [3:0] red_data,      // Red data bits of RGB data for VGA port.
    output [3:0] green_data,    // Green data bits of RGB data for VGA port.
    output [3:0] blue_data      // Blue data bits of RGB data for VGA port.
    );

    // Define constants for character width (8) and height (16).
    localparam CHAR_WIDTH = 8;
    localparam CHAR_HEIGHT = 16;

    // Displaying to screen.
    wire top_left_cell;
    reg [3:0] red_data_reg, green_data_reg, blue_data_reg;
    assign top_left_cell = (x_pos < 8) && (y_pos < 16);
    always @(posedge pixel_clk) begin
        // Limit display only to top left cell of dispplay.
        if(display_on && top_left_cell) begin
            red_data_reg <= char_data[23:20];
            green_data_reg <= char_data[15:12];
            blue_data_reg <= char_data[7:4];
        end
        else begin
            red_data_reg <= 4'b0;
            green_data_reg <= 4'b0;
            blue_data_reg <= 4'b0;
        end
    end

    // Assign outputs.
    assign red_data = red_data_reg;
    assign green_data = green_data_reg;
    assign blue_data = blue_data_reg;
    
endmodule
