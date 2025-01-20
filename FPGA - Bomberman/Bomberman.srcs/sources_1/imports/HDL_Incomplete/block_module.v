
module block_module
(
   output wire [15:0] led,
   input wire clk, reset, display_on,
   input wire [9:0] x, y, x_a, y_a,     // current pixel location on screen, without and with arena offset subtracted
   input wire [1:0] cd,                 // bomberman current direction
   input wire [9:0] x_b, y_b,           // bomberman coordinates
   input wire [9:0] waddr,              // write address (a) into block map RAM
   input wire we,                       // write enable to block map RAM
   output wire [11:0] rgb_out,          // output block rgb
   output wire block_on,                // asserted when x/y within block location on screen
   output wire bm_blocked               // asserted when bomberman is blocked by a block at current location and direction
);

// Bombermabn current directions.
localparam CD_U = 2'b00;
localparam CD_R = 2'b01;
localparam CD_D = 2'b10;
localparam CD_L = 2'b11;

// Arena boundaries.
localparam X_WALL_L = 48;
localparam X_WALL_R = 576;
localparam Y_WALL_U = 32;
localparam Y_WALL_D = 448;

// Bomberman parameters.
localparam UP_LEFT_X   = 48;                    // constraints of Bomberman sprite location (upper left corner) within arena.
localparam UP_LEFT_Y   = 32;
localparam BM_HB_OFFSET_9 = 8;
localparam BM_HB_HALF     = 8;                  // half length of bomberman hitbox
localparam BM_WIDTH       = 16;
localparam BM_HEIGHT      = 24;

// Write State Machine states.
localparam IDLE                  = 0;
localparam SET_READ_ADDRESS      = 1;
localparam WRITE                 = 1;
localparam READ                  = 2;
localparam PROCESS_DATA_OUT      = 3;

// Power up probabilities. 
localparam PROB_POWER_UP = 3'b011;     // Chance of getting a power up.
localparam PROB_RANGE_UP = 3'b110;     // Chance of that power up being a bomb range increase. UNUSED.
localparam PROB_SPEED_UP = 3'b101;     // Chance of that power up being a speed up token.

// Block Ram Data masks for multiplexing between the three.
localparam GARABGE = 3'b000;           // Mask to identify no block data and garbage values.
localparam BLOCK_MASK = 3'b110;        // Mask to identify Block data in global register.
localparam POWERUP_MASK = 3'b011;      // Mask to identify Power Up Location and Type in global register.
localparam BLOCK_ACTIVE = 3'b100;      // Mask representing Block state within block map.
localparam PU_ACTIVE = 3'b010;         // Mask representing Power Up state within power up location map.
localparam SPEED_TYPE = 3'b001;        // Mask representing Speed Up power up within power up type map.
localparam RANGE_TYPE = 3'b000;        // Mask representing Increase Range power up within power up type map.

// Wires.
wire [9:0] x_b_hit_l;                  // used to index into block_map RAM to determine if bomberman will collide with a box.
wire [9:0] x_b_hit_r;                  // if moving in a specific direction at the current location. format: <coordinate>_b_hit_<left, right, bottom, top>
wire [9:0] y_b_hit_b; 
wire [9:0] y_b_hit_t;
wire [9:0] y_b_hit_lr;
wire [9:0] x_b_hit_bt; 

wire [7:0] block_or_pu_addr;           // Bus holding the read address to index into the ROMs.
wire [15:0] random;                    // Bus carrying the output of the LFSR used for randomization.
wire pu_type_map_data_in;              // Wire for data input to the map that stores Power up Location. 
wire pu_loc_map_data_in;               // Wire for data input to the map that stores Power up types. 
wire block_map_data_in;                // Wire for data input to the map that stores Block locations. 
wire pu_type_map_data_out;             // Wire for data output to the map that stores Power up Location. 
wire pu_loc_map_data_out;              // Wire for data output to the map that stores Power up types. 
wire block_map_data_out;               // Wire for data input to the map that stores Block locations. 
wire [11:0] block_sprite_out;          // Wire to pass data output from the block ROM for display purposes.
wire [11:0] speed_up_sprite_out;       // Wire to pass data output from the speed power-up ROM for display purposes.
wire [11:0] bomb_radius_sprite_out;    // Wire to pass data output from the bomb radius power-up ROM for display purposes.
wire within_arena;                     // Wire to see if the cursor main X and Y coordinates are within the Arena region.

// Registers.  
reg [2:0] read_state_reg;              // Register to hold the state of the decision making state machine.
reg [2:0] read_state_next;             // Buffer register for the above.
reg [9:0] raddr_reg;                   // Register to hold the read address to be used with block RAMs.
reg [9:0] raddr_next;                  // Buffer register for the above.
reg [9:0] waddr_reg;                   // Register to hold the write address to be used with block RAMs.
reg [9:0] waddr_next;                  // Buffer register for the above.
reg [2:0] map_data_in_reg;             // 3-bit global state register to hold the data input corresponding to power up and block relationships.
reg [2:0] map_data_in_next;            // Buffer register for the above.
reg [2:0] map_data_out_reg;            // 3-bit global state register to hold the data output corresponding to power up and block relationships.
reg [2:0] map_data_out_next;           // Buffer register for the above.
reg [2:0] write_state_reg;             // Register that controls writes for powerups or no powerups after explosion.
reg [2:0] write_state_next;            // Buffer register for the above.
reg [5:0] random_reg;                  // Register that latches 3 random bits from the LFSR for use in decision making.
reg [9:0] x_bomb_reg;                  // Bomb X coordinate translated to arena coords.  
reg [9:0] y_bomb_reg;                  // Bomb Y coordinate translated to arena coords. 
reg [9:0] x_bomb_next;                 // Buffer register for the above.
reg [9:0] y_bomb_next;                 // Buffer register for the above.
reg blocked_reg;                       // Register to hold state indicating if bomberman's movement is blocked by the coming block (or powerups).
reg blocked_next;                      // Buffer register for the above.
reg powerup_reg;                       // Register to hold state indicating if the coming block is a power up.
reg powerup_next;                      // Buffer register for the above.
reg pu_placed_reg;                     // Register to hold state indicating if 1 pu/explosion has been reached.
reg pu_placed_next;                    // Buffer register for the above.

// Continuous Assignments. 
assign within_arena = (x > X_WALL_L) & (x < X_WALL_R) & (y > Y_WALL_U) & y < (Y_WALL_D + 16);
assign block_or_pu_addr = x_a[3:0] + {(y_a[3:0]), 4'd0};       // Index into ROM uses x/y pixel arena coordinates lower 4 bits, as each block is 16x16.
assign block_map_data_in = map_data_in_reg[2];                 // Mask to see if global register indicates input should be provided to Block Map.
assign pu_loc_map_data_in = map_data_in_reg[1];                // Mask to see if global register indicates input should be provided to Power Up Location Map.
assign pu_type_map_data_in = map_data_in_reg[0];               // Mask to see if global register indicates input should be provided to Power UP Type Map.
assign block_on = display_on & map_data_out_reg[2];            // Asserted when x and y pixel coordinates have indexed into a block.
assign bm_blocked = blocked_reg;                               // Ensure that the proper signal indicating bomberman's blocked status is asserted
assign block_is_powerup = powerup_reg;                         // Ensure that the proper signal indicating block power up status is asserted.

assign x_b_hit_l  = x_b - 1 - X_WALL_L;                     // x coordinate of left  edge of hitbox
assign x_b_hit_r  = x_b + BM_WIDTH - X_WALL_L;              // x coordinate of right edge of hitbox
assign y_b_hit_lr = y_b + BM_HB_OFFSET_9 + 8 - Y_WALL_U;    // y coordinate of middle of hit box
assign y_b_hit_b  = y_b + BM_HEIGHT - Y_WALL_U;             // y coordiante of bottom of hitbox if sprite were going to move down (y + 1)
assign y_b_hit_t  = y_b + BM_HB_OFFSET_9 - 1 - Y_WALL_U;    // y coordinate of top of hitbox if sprite were going to move up (y - 1)
assign x_b_hit_bt = x_b + 7 - X_WALL_L;                     // x coordinate of middle of hitbox

// Change output based on block or power up being displayed.
assign rgb_out =  ((map_data_out_reg & BLOCK_MASK) == GARABGE)                      ?  12'b1                   :          
                  ((map_data_out_reg & BLOCK_MASK) == (BLOCK_ACTIVE | !PU_ACTIVE))  ?  block_sprite_out        :
                  ((map_data_out_reg & POWERUP_MASK) == (PU_ACTIVE | SPEED_TYPE))   ?  speed_up_sprite_out     :
                  ((map_data_out_reg & POWERUP_MASK) == (PU_ACTIVE | RANGE_TYPE))   ?  bomb_radius_sprite_out  : 
                  12'b1;

reg led_reg;
always @(posedge clk or negedge reset) begin
    if (!reset)
        led_reg <= 0;
    else if (raddr_reg == waddr_reg)
        led_reg <= 1;
end

assign led[15] = led_reg;

// Module Instantiations. 
LFSR_16 LFSR_16_unit(                  // Module to generate pseduo-random numbers.
   .clk(clk), 
   .rst(reset), 
   .w_en(), 
   .w_in(), 
   .out(random)
   );             

block_dm block_unit(                   // Module to provide data for Block video output. ROM.
   .a(block_or_pu_addr), 
   .spo(block_sprite_out)
   );          

speed_up_dm speed_power_up(            // Module to provide data for Speed Power-up video output. ROM.
   .a(block_or_pu_addr), 
   .spo(speed_up_sprite_out)
   );                          

bomb_radius_dm range_power_up(         // Module to provide data for Block Radius Power-up video output. ROM.
   .a(block_or_pu_addr), 
   .spo(bomb_radius_sprite_out)
   );                    

block_map block_map_unit(              // Module to provide information on the presence of blocks in the arena. Distributed Dual Port RAM.
   .a(waddr), 
   .d(block_map_data_in), 
   .dpra(raddr_reg), 
   .clk(clk), 
   .we(we), 
   .spo(), 
   .dpo(block_map_data_out)
   );        

power_up_map_dm pu_loc_map(            // Module to provide information on the presence of power ups in the arena. Distributed Dual Port RAM.
   .a(waddr), 
   .d(pu_loc_map_data_in), 
   .dpra(raddr_reg), 
   .clk(clk), 
   .we(we), 
   .spo(), 
   .dpo(pu_loc_data_out)
   );        

power_up_map_dm pu_type_map(           // Module to provide information on the type of power ups active in the arena. Distributed Dual Port RAM.
   .a(waddr), 
   .d(pu_type_map_data_in), 
   .dpra(raddr_reg), 
   .clk(clk), 
   .we(we), 
   .spo(), 
   .dpo(pu_type_data_out)
   );     

//************************************************************** PILLAR COLLISION SIGNALS *************************************************************

// pillar collision signals, asserted when sprite hit box will collide with 
// left, right, top, bottom side of pillar if sprite hitbox where to 
// move in that direction.
wire p_c_up, p_c_down, p_c_left, p_c_right;

// determine p_c_down & p_c_up signals:

wire [9:0] x_bomb_hit_l, x_bomb_hit_r, y_bomb_bottom, y_bomb_top;
assign x_bomb_hit_l  = x_bomb_reg - UP_LEFT_X;                        // x coordinate of left  edge of hitbox
assign x_bomb_hit_r  = x_bomb_reg - UP_LEFT_X + BM_WIDTH - 1;         // x coordinate of right edge of hitbox
assign y_bomb_bottom = y_bomb_reg - UP_LEFT_Y + BM_HEIGHT + 1;        // y coordiante of bottom of hitbox if sprite were going to move down (y + 1)
assign y_bomb_top    = y_bomb_reg - UP_LEFT_Y + BM_HB_OFFSET_9 - 1;   // y coordinate of top of hitbox if sprite were going to move up (y - 1)


// sprite will collide if going down if the bottom of the hitbox would be within a pillar (5th bit == 1), 
// and either the left or right edges of the hit box are within the x coordinates of a pillar (5th bit == 1)
assign p_c_down = ((y_bomb_bottom[4] == 1) & (x_bomb_hit_l[4] == 1 | x_bomb_hit_r[4] == 1));   

// sprite will collide if going up if the top of the hitbox would be within a pillar (5th bit == 1), 
// and either the left or right edges of the hit box are within the x coordinates of a pillar (5th bit == 1)
assign p_c_up   = ((   y_bomb_top[4] == 1) & (x_bomb_hit_l[4] == 1 | x_bomb_hit_r[4] == 1));

// determine p_c_left & p_c_right signals:

wire [9:0] y_bomb_hit_t, y_bomb_hit_b, x_bomb_left, x_bomb_right;
assign y_bomb_hit_t = y_bomb_reg - UP_LEFT_Y + BM_HB_OFFSET_9; // y coordinate of the top edge of the hitbox
assign y_bomb_hit_b = y_bomb_reg - UP_LEFT_Y + BM_HEIGHT -1;   // y coordiate of the bottom edge of the hitbox
assign x_bomb_left  = x_bomb_reg - UP_LEFT_X - 1;              // x coordinate of the left edge of the hitbox if the sprite were going to move left (x - 1)
assign x_bomb_right = x_bomb_reg - UP_LEFT_X + BM_WIDTH + 1;   // x coordinate of the right edge of the hitbox if the sprite were going to move right (x + 1)


// sprite will collide if going left if the left edge of the hitbox would be within a pillar (5th bit == 1), 
// and either the top or bottom edges of the hit box are within the x coordinates of a pillar (5th bit == 1)
assign p_c_left  = ( (x_bomb_left[4] == 1) & (y_bomb_hit_t[4] == 1 | y_bomb_hit_b[4] == 1)) ? 1 : 0;

// sprite will collide if going right if the right edge of the hitbox would be within a pillar (5th bit == 1), 
// and either the top or bottom edges of the hit box are within the x coordinates of a pillar (5th bit == 1)

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ Read State Machine +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Update State Machine Current Registers on Clock or Reset.
always @(posedge clk, posedge reset) begin
   if(reset) begin
      raddr_reg         <= 896;
      blocked_reg       <= 0;
      powerup_reg       <= 0;
      read_state_reg    <= IDLE;
      map_data_out_reg  <= (!BLOCK_ACTIVE | !PU_ACTIVE);
   end
   else begin
      raddr_reg         <= raddr_next;
      blocked_reg       <= blocked_next;
      powerup_reg       <= powerup_next;
      read_state_reg    <= read_state_next;
      map_data_out_reg  <= map_data_out_next;
   end
end

// Update State Machine Next State Registers.
always @* begin

   // Defaults.
   raddr_next = raddr_reg;
   blocked_next = blocked_reg;
   powerup_next = powerup_reg;
   read_state_next = read_state_reg;
   map_data_out_next = map_data_out_reg;

   // FSM.
   case (read_state_reg)

      // Identify operation called on this module and perform accordingly.
      IDLE : begin
         if(!we) ;
         read_state_next = SET_READ_ADDRESS;
      end

      SET_READ_ADDRESS: begin

         // Read address for brick rgb output.
         if(within_arena && display_on) raddr_next = x_a[9:4] + y_a[9:4] * 33;

         // read address for collision detection with brick. 
         else if(!display_on) begin
            case (cd)
               CD_L: raddr_next = x_b_hit_l[9:4] + y_b_hit_lr[9:4] * 33;                                                         
               CD_R: raddr_next = x_b_hit_r[9:4] + y_b_hit_lr[9:4] * 33;
               CD_U: raddr_next = x_b_hit_bt[9:4] + y_b_hit_t[9:4] * 33;
               CD_D: raddr_next = x_b_hit_bt[9:4] + y_b_hit_b[9:4] * 33;
            endcase
         end

         // Garbage read address for when display on and we're not within the arena.
         else raddr_next = 896;
         
         // Update state.
         read_state_next = READ;
      end

      // Gave data out time to propogate to output.
      READ : begin
         map_data_out_next = {block_map_data_out, pu_loc_data_out, pu_type_data_out};
         read_state_next = PROCESS_DATA_OUT;
      end

      // Process the data from the RAM and assign the appropriate signals.
      PROCESS_DATA_OUT : begin   
         
         // Determine if the upcoming block is a powerup.
         powerup_next = ((!display_on) && (map_data_out_reg & PU_ACTIVE)      == PU_ACTIVE) ? 1 : 
                        ((!display_on) && (map_data_out_reg & PU_ACTIVE)      == PU_ACTIVE) ? 0 : powerup_reg;

         // Determine if bombermans movment is blocked by an upcoming block.
         blocked_next = ((!display_on) && ((map_data_out_reg & BLOCK_MASK) == (BLOCK_ACTIVE | !PU_ACTIVE)))  ?  1  : 
                        ((!display_on) && ((map_data_out_reg & BLOCK_MASK) != (BLOCK_ACTIVE | !PU_ACTIVE)))  ?  0  : blocked_reg;
         // Update state.
         read_state_next = IDLE;
      end
   endcase
end
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ Write State Machine +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Update State Machine Current Registers on Clock or Reset.
always @(posedge clk, posedge reset) begin
   if(reset) begin
      waddr_reg         <= 896;
      write_state_reg   <= IDLE;
      map_data_in_reg   <= BLOCK_ACTIVE;
      random_reg        <= 0;
      x_bomb_reg        <= 0;
      pu_placed_reg     <= 0;
   end
   else begin
      waddr_reg         <= waddr_next;
      write_state_reg   <= write_state_next;
      map_data_in_reg   <= map_data_in_next;
      random_reg        <= random[7:2];
      x_bomb_reg        <= x_bomb_next;
      pu_placed_reg     <= pu_placed_next;
   end
end

// Update State Machine Next State Registers.
always @* begin

   // Default assignments (avoiding latches).
   waddr_next           = waddr_reg;
   write_state_next     = write_state_reg;
   map_data_in_next     = map_data_in_reg;
   x_bomb_next          = x_bomb_reg;
   pu_placed_next       = pu_placed_reg;

   // Enter write state machine.
   case (write_state_reg)
      // Waiting for explosion to occur.
      IDLE : begin
         if(we) begin
            // Grab bomb coordinates in Arena Coordinates.
            x_bomb_next = x_b + BM_HB_HALF - X_WALL_L;                       
            y_bomb_next = y_b + BM_HB_HALF + BM_HB_OFFSET_9 - Y_WALL_U;      

            // Update state.
            
            write_state_next = WRITE;
         end
      end

      // Write to the 3 maps randomly. Bias towards no powerup.
      WRITE : begin
         
         if((p_c_up) || (p_c_down) || (p_c_left) || (p_c_right)) map_data_in_next = (!BLOCK_ACTIVE);

         // No power up. Allow only one power up per explosion.
         else if(random_reg[2:0] >= PROB_POWER_UP || pu_placed_reg) map_data_in_next = (!BLOCK_ACTIVE);
     
         // Power Up is behind block. Select btwn speed and range.
         else begin
            // Speed up power up selected.
            if(random_reg[5:3] <= PROB_SPEED_UP) map_data_in_next = (BLOCK_ACTIVE | PU_ACTIVE | SPEED_TYPE);

            // Increase bomb range power up selected.
            else map_data_in_next = (BLOCK_ACTIVE | PU_ACTIVE | RANGE_TYPE);

            // Signal that power up was placed.
            pu_placed_next = 1;
         end

         // Udpate write address for writing in ther next cycle.
         waddr_next = waddr;
         
         // Update state.
         if(!we) begin
            pu_placed_next = 0;
            write_state_next = IDLE;
         end
      end

   endcase
end
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//


endmodule
