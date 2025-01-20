
/*
Linear Feedback Shift Register for Enemey Sprite Movement. 
Using the polynomial x^16 + x^14 + x^3 +x^11 + 1, 
taps are at 16, 14, 13, 11 .
*/
module LFSR_16 (
    input wire clk, rst, w_en,
    input wire [15:0] w_in,
    output wire [15:0] out
    );
    
    // Internal signals.
    reg [15:0] out_reg;
    
     // Assign the feedback and output.
    wire feedback = out[15] ^ out[13] ^ out[12] ^ out[10];
    assign out = out_reg;
    
    // Provide output or perform shift. Reset if needed.
    always @(posedge clk or posedge rst) begin     

        // Initialize to defualt value.
        if (rst) out_reg <= 16'h4447;

        // Provide output if write enabled.
        else if (w_en) out_reg <= w_in;

        // Shift and feedback.
        else out_reg <= {out_reg[14:0], feedback};
    end
    
endmodule
