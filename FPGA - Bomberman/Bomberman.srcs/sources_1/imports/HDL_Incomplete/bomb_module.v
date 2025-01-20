module bomb_module
(
   input wire clk, reset, pause,
   input wire [9:0] x_a, y_a,              // current pixel location on screen in arena coordinate frame
   input wire [1:0] cd,                    // bomberman current direction
   input wire [9:0] x_b, y_b,              // bomberman coordinates
   input wire A,                           // bomb button input
   input wire gameover,                    // signal from game_lives module, asserted when gameover
   input wire expand_range,                // Signal from block module, asserted when bomberman passes an "increase bomb range" powerup.
   output wire [11:0] bomb_rgb, exp_rgb,   // rgb output for bomb and explosion tiles
   output wire bomb_on, exp_on,            // signals asserted when vga x/y pixels are within bomb or explosion tiles on screen
   output wire [9:0] block_w_addr,         // adress into block map RAM of where explosion is to clear block
   output wire block_we,                   // write enable signal into block map RAM
   output wire post_exp_active             // signal asserted when bomb_exp_state_reg == post_exp, bomb is active on screen
);

// Bomberman parmerters.
localparam BM_HB_OFFSET_9 = 8;             // offset from top of sprite down to top of 16x16 hit box  
localparam BM_HB_HALF     = 8;             // half length of bomberman hitbox

// Arena boundaries.
localparam X_WALL_L = 48;                  // end of left wall x coordinate
localparam X_WALL_R = 576;                 // begin of right wall x coordinate
localparam Y_WALL_U = 32;                  // bottom of top wall y coordinate
localparam Y_WALL_D = 448;                 // top of bottom wall y coordinate

// Bomb and explosion timer limits.
localparam BOMB_COUNTER_MAX = 220000000;   // max values for counters used for bomb and explosion timing
localparam EXP_COUNTER_MAX  = 120000000;

// Bomb states.
localparam [3:0] no_bomb = 3'b000;        // no bomb on screen
localparam [3:0] bomb = 3'b001;           // bomb on screen for 1.5 s
localparam [3:0] exp_left = 3'b010;       // take care of explosion tile 1
localparam [3:0] exp_right = 3'b011;      // 2
localparam [3:0] exp_top = 3'b100;        // 3
localparam [3:0] exp_bottom = 3'b101;     // 4
localparam [3:0] post_exp = 3'b110;       // wait for .75 s to finish                     

// Wires.
wire [27:0] bomb_counter_next;
wire [26:0] exp_counter_next;
wire [4:0] exp_range_next;
wire [9:0] x_bomb_a;                                  // Bomb X coordinate translated to arena coords.  
wire [9:0] y_bomb_a;                                  // Bomb Y coordinate translated to arena coords. 
wire [9:0] exp_addr;                                  // Address where explosion sprite is to be written.

// Registers.
reg [3:0] bomb_exp_state_reg, bomb_exp_state_next;    // FSM register and next-state logic
reg [5:0] bomb_x_reg, bomb_y_reg;                     // bomb ABM coordinate location register 
reg [5:0] bomb_x_next, bomb_y_next;                   // and next-state logic
reg bomb_active_reg, bomb_active_next;                // register asserted when bomb is on screen
reg exp_active_reg, exp_active_next;                  // register asserted when explosion is active on screen.
reg [9:0] exp_block_addr_reg, exp_block_addr_next;    // address to write a 0 to block map to clear a block hit by explosion.
reg block_we_reg, block_we_next;                      // register to enable block map RAM write enable
reg [27:0] bomb_counter_reg;                          // counter register to track how long a bomb exists before exploding
reg [26:0] exp_counter_reg;                           // counter register to track how long an explosion lasts
reg post_exp_active_reg, post_exp_active_next;        // Register to indicate the post explosion state.
reg [4:0] exp_range_reg;                              // Register to indicate the current range of the bomb.      
reg [4:0] exp_index_reg, exp_index_next;              // Regsiter to indicate the current cell being exploded within a range.

// Continuous Assignments.
assign x_bomb_a = x_b + BM_HB_HALF - X_WALL_L;                       // Translate bomb x to arena x for display purposes.
assign y_bomb_a = y_b + BM_HB_HALF + BM_HB_OFFSET_9 - Y_WALL_U;      // Translate bomb y to arena y for display purposes.
assign block_w_addr = exp_block_addr_reg;                            // assign explosion block map write address to output
assign block_we = block_we_reg;                                      // assign block map write enable to output
assign post_exp_active = post_exp_active_reg;                        // assign post explosion signal.
assign bomb_on = (x_a[9:4] == bomb_x_reg & y_a[9:4] == bomb_y_reg & bomb_active_reg);     // bomb_on asserted when bomb x/y arena block map coordinates equal that of x/y ABM coordinates and bomb is active
assign bomb_counter_next = (bomb_active_reg & bomb_counter_reg < BOMB_COUNTER_MAX) && (!pause) ? bomb_counter_reg + 1 : 0;    // Next state logic for Bomb Counter.
assign exp_counter_next = (exp_active_reg & exp_counter_reg < EXP_COUNTER_MAX) && (!pause) ? exp_counter_reg + 1 : 0;         // Next state logic for Explosion Counter.
assign exp_range_next = (expand_range) ? exp_range_reg + 1 : exp_active_reg;     // Next state logic for explosion range.

// explosion_on asserted when appropriate tile location with respect to bomb ABM coordinates matches
// x/y ABM coordinates
assign exp_on = (exp_active_reg &(
                (                   x_a[9:4] == bomb_x_reg   & y_a[9:4] == bomb_y_reg  ) |  // center
                (bomb_x_reg != 0  & x_a[9:4] == bomb_x_reg-1 & y_a[9:4] == bomb_y_reg  ) |  // exp_left
                (bomb_x_reg != 32 & x_a[9:4] == bomb_x_reg+1 & y_a[9:4] == bomb_y_reg  ) |  // exp_right
                (bomb_y_reg != 0  & x_a[9:4] == bomb_x_reg   & y_a[9:4] == bomb_y_reg-1) |  // exp_left
                (bomb_y_reg != 26 & x_a[9:4] == bomb_x_reg   & y_a[9:4] == bomb_y_reg+1))); // exp_right

// Set the explosion address in arena coordinates
assign exp_addr = (                   x_a[9:4] == bomb_x_reg   & y_a[9:4] == bomb_y_reg  ) ? x_a[3:0] + (y_a[3:0] << 4)              : // center
                  (bomb_x_reg != 0  & x_a[9:4] == bomb_x_reg-1 & y_a[9:4] == bomb_y_reg  ) ? (15 - x_a[3:0]) + ((y_a[3:0] + 16) << 4): // exp_left
                  (bomb_x_reg != 32 & x_a[9:4] == bomb_x_reg+1 & y_a[9:4] == bomb_y_reg  ) ? x_a[3:0] + ((y_a[3:0] + 16) << 4)       : // exp_right
                  (bomb_y_reg != 0  & x_a[9:4] == bomb_x_reg   & y_a[9:4] == bomb_y_reg-1) ? x_a[3:0] + ((y_a[3:0] + 32) << 4)       : // exp_top
                  (bomb_y_reg != 26 & x_a[9:4] == bomb_x_reg   & y_a[9:4] == bomb_y_reg+1) ? x_a[3:0] + (((15 - y_a[3:0]) + 32) << 4)  // exp_bottom
                  : 0;
                       
// Module Instantiations. 
bomb_dm bomb_dm_unit(.a((x_a[3:0]) + {y_a[3:0], 4'd0}), .spo(bomb_rgb));                  // instantiate bomb sprite ROM
explosions_br exp_br_unit(.clka(clk), .ena(1'b1), .addra(exp_addr), .douta(exp_rgb));     // instantiate explosions sprite ROM

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// infer bomb counter register
always @(posedge clk, posedge reset) begin
   if(reset) bomb_counter_reg <= 0;
   else bomb_counter_reg <= bomb_counter_next;
end

// infer explosion counter register
always @(posedge clk, posedge reset) begin
   if(reset) exp_counter_reg <= 0;
   else exp_counter_reg <= exp_counter_next;
end

//////////////////////////////****************************** Bomb Placement and Explosion Finite State Machine ******************************//////////////////////////////

// Update State Machine Current Registers on Clock or Reset.
always @(posedge clk, posedge reset, posedge pause) begin
   if(reset) begin
      bomb_exp_state_reg   <= no_bomb;
      bomb_active_reg      <= 0;
      exp_active_reg       <= 0;
      bomb_x_reg           <= 0;
      bomb_y_reg           <= 0;
      exp_block_addr_reg   <= 0;
      block_we_reg         <= 0;
      post_exp_active_reg  <= 0;
      exp_range_reg        <= 1;
      exp_index_reg        <= 0;
   end else if(pause); // Do nothing. just don's update values.
   else begin
      bomb_exp_state_reg   <= bomb_exp_state_next;
      bomb_active_reg      <= bomb_active_next;
      exp_active_reg       <= exp_active_next;
      bomb_x_reg           <= bomb_x_next;
      bomb_y_reg           <= bomb_y_next;
      exp_block_addr_reg   <= exp_block_addr_next;
      block_we_reg         <= block_we_next;
      post_exp_active_reg  <= post_exp_active_next;
      exp_range_reg        <= exp_range_next;
      exp_index_reg        <= exp_index_next;
   end
end

// Update State Machine Next State Registers.
always @* begin 

   // Default assignments (avoiding latches).
   bomb_exp_state_next     = bomb_exp_state_reg;
   bomb_active_next        = bomb_active_reg;
   exp_active_next         = exp_active_reg;
   bomb_x_next             = bomb_x_reg;
   bomb_y_next             = bomb_y_reg;
   exp_block_addr_next     = exp_block_addr_reg;
   block_we_next           = block_we_reg;
   post_exp_active_next    = post_exp_active_reg;
   exp_index_next          = exp_index_reg;

   // FSM Transition logic.
   case(bomb_exp_state_reg)

      // No bomb or explosion. No counters have started.
      no_bomb  :  begin
         if(A && !gameover) begin
            // Updatate bomb activity and location.
            bomb_active_next = 1;
            bomb_x_next = x_bomb_a[9:4];
            bomb_y_next = y_bomb_a[9:4];

            // Update state.
            bomb_exp_state_next = bomb;
         end 
      end

      // Bomb displayed for a bit.
      bomb     :  begin
         if(bomb_counter_reg == BOMB_COUNTER_MAX) begin
            // Update bomb and explosion activity. Allow writing to remove blocks.
            bomb_active_next = 0;
            exp_active_next = 1; 
            block_we_next = 1;

            // Update state.
            bomb_exp_state_next = exp_left;
         end
      end

      // Left hand side of the explosion occurs.
      exp_left    :  begin
         // Remain in left explosion until range runs out.
         if(exp_index_reg != exp_range_reg) begin
            exp_block_addr_next = (bomb_x_next - 1 - exp_index_next*16) + bomb_y_next * 33;
            exp_index_next = exp_index_next + 1;
         end

         // Reset explosion index and leave left.
         else begin
            exp_index_next = 0;
            exp_block_addr_next = 0;
            bomb_exp_state_next = exp_right;  
         end 
      end

      // Right hand side of the explosion occurs.
      exp_right    :  begin
         // Remain in right explosion until range runs out.
         if(exp_index_reg != exp_range_reg) begin
            exp_block_addr_next = (bomb_x_next + 1 + exp_index_next*16) + bomb_y_next * 33;
            exp_index_next = exp_index_next + 1;
         end

         // Reset explosion index and leave right.
         else begin
            exp_index_next = 0;
            exp_block_addr_next = 0;
            bomb_exp_state_next = exp_top;  
         end
      end
      
      // Top side of the explosion occurs.
      exp_top    :  begin
         // Remain in top explosion until range runs out.
         if(exp_index_reg != exp_range_reg) begin
            exp_block_addr_next = bomb_x_next + (bomb_y_next - 1 - exp_index_next*16) * 33;
            exp_index_next = exp_index_next + 1;
         end

         // Reset explosion index and leave top.
         else begin
            exp_index_next = 0;
            exp_block_addr_next = 0;
            bomb_exp_state_next = exp_bottom;  
         end
      end

      // Bottom side of the explosion occurs.
      exp_bottom    :  begin
         // Remain in bottom explosion until range runs out.
         if(exp_index_reg != exp_range_reg) begin
            exp_block_addr_next = bomb_x_next + (bomb_y_next + 1 + exp_index_next*16) * 33;
            exp_index_next = exp_index_next + 1;
         end

         // Reset explosion index and leave bottom.
         else begin
            exp_index_next = 0;
            exp_block_addr_next = 0;
            bomb_exp_state_next = post_exp;  
         end
      end
      
      // Allow the explosion some time then remove.
      post_exp :  begin
         if (exp_counter_reg == EXP_COUNTER_MAX) begin
            // De-assert post explosion.
            post_exp_active_next = 0;
            exp_active_next = 0;
            block_we_next = 0;
            
            // Update state;
            bomb_exp_state_next = no_bomb;
         end

         // Assert post explosion.
         else post_exp_active_next = 1;
      end
   endcase
end        
                              
endmodule

