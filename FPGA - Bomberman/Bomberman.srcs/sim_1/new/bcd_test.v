module bcd_test();
    reg clk, reset, start;
    reg [13:0] in;
    wire [3:0] bcd3, bcd2, bcd1, bcd0;
    wire [3:0] count;
    wire [1:0] state;

    // Instantiate the binary2bcd module
    binary2bcd uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .in(in),
        .bcd3(bcd3),
        .bcd2(bcd2),
        .bcd1(bcd1),
        .bcd0(bcd0),
        .count(count),
        .state(state)
    );

    // Generate clock
    always #5 clk = ~clk;
    
    // Wire for adding.
    reg [13:0] sum = 0;
    
    initial begin
        // Initialize signals
        clk = 0; reset = 1; start = 0; in = 14'd0;

        // Apply reset
        #10 reset = 0;
        
        forever begin
            // Test case 1: Binary 0
            #100 
            start = 1; 
            in = sum;
            
            #100 
            start = 0;
            sum = sum + 1;
            
            #100;
            if(sum > 14'd10000) $finish;
        end
       
    end
endmodule
