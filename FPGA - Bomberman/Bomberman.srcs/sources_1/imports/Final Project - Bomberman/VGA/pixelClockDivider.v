`timescale 1ns / 1ps

/*
    Pixel Clock Divider Module:
    Module to divide 100 MHz main system clock down to 25 MHz 
    to properly drive the VGA_Controller Module.
    Using the following formula: fout = fin/2N, N = reg size, 
    Is how the clock division is performed.
*/
module pixelClockDivider(
    input clk,              // Basys 3 main system clock.
    output reg pixel_clk    // Divided clock signal output.
    );

    // Initialize count register and pixel clock.
    reg [1:0] count;
	initial begin
		count = 0;
		pixel_clk = 0;
    end  

    // Toggle pixel clock.
    always@(posedge clk) begin
        if(count == 2 - 1) begin
            pixel_clk = ~pixel_clk;
            count = 0;
        end
        else count <= count + 1;
    end
endmodule
