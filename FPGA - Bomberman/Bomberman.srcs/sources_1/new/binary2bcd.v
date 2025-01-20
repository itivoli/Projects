
module binary2bcd (
    input wire clk, reset,
    input wire start,
    input wire [13:0] in,
    output wire [3:0] bcd3, bcd2, bcd1, bcd0,
    output wire [3:0] count,
    output wire [1:0] state
    );

    // States.
    localparam  [1:0]   IDLE = 2'b00,           // Not converting.
                        LOAD = 2'b01,           // Loading the number to convert to BCD.
                        SHIFT_N_ADD = 2'b10,    // Perform the shifting process.
                        DONE = 2'b11;           // Assert the output and finish.

    // Internal registers necessary registers for conversion.
    reg [3:0] bcd3_reg, bcd2_reg, bcd1_reg, bcd0_reg; 
    reg [4:0] shift_counter; 
    reg start_reg;
    reg [3:0] count_reg;
    reg [1:0] state_reg;
    reg [29:0]  scratch_reg;
    reg add_phase;

    // Assign outputs.
    assign bcd3 = bcd3_reg;
    assign bcd2 = bcd2_reg;
    assign bcd1 = bcd1_reg;
    assign bcd0 = bcd0_reg;
    assign count = shift_counter;
    assign state = state_reg;

    // State machine.
    always @(posedge clk or posedge reset) begin

        // Reset signals if required.
        if (reset) begin
            add_phase = 0;
            bcd3_reg <= 0; bcd2_reg <= 0; bcd1_reg <= 0; bcd0_reg <= 0;
            shift_counter <= 0;
            state_reg <= IDLE;
            scratch_reg <= 0;
        end 

        // Decoding procedure.
        else begin

            // Begin decoding. 
            case (state_reg)

                // No conversion. Just waiting for start signal given. Update state.
                IDLE:  if(start)  state_reg <= LOAD;

                // Load in data for conversions.
                LOAD: begin
                    // Load in 14-bit input.
                    scratch_reg <= {4'b000, 4'b000, 4'b000, 4'b000, in};

                    // Update state.
                    add_phase = 0;
                    state_reg <= SHIFT_N_ADD;
                end

                // Perform the shifting process.
                SHIFT_N_ADD: begin

                    // Conversion in process.
                    if (shift_counter < 14) begin
                        // Shift the field left by 1 bit and increment shift counter.
                        if(!add_phase) begin
                            scratch_reg <= scratch_reg << 1;
                            shift_counter <= shift_counter + 1;
                        end
                        
                        // Check to see if any BCD digit is >= 5. Add 3 if so.
                        else begin
                            if (scratch_reg[29:26] >= 5) scratch_reg[29:26] <= scratch_reg[29:26] + 3;
                            if (scratch_reg[25:22] >= 5) scratch_reg[25:22] <= scratch_reg[25:22] + 3;
                            if (scratch_reg[21:18] >= 5) scratch_reg[21:18] <= scratch_reg[21:18] + 3;
                            if (scratch_reg[17:14] >= 5) scratch_reg[17:14] <= scratch_reg[17:14] + 3;
                        end

                        // Toggle shift/add.
                        add_phase = add_phase ^ 1;
                    end  
                    
                    // Conversion complete. 
                    else begin
                        // Update BCD registers.
                        bcd3_reg <= scratch_reg[29:26];
                        bcd2_reg <= scratch_reg[25:22];
                        bcd1_reg <= scratch_reg[21:18];
                        bcd0_reg <= scratch_reg[17:14];

                        // Reset counter.
                        shift_counter <= 0;

                        // Update state.
                        state_reg <= DONE;
                    end
                end

                // Output ready, move on.
                DONE: state_reg <= IDLE;
            endcase
        end
    end
endmodule
