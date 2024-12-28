`timescale 1ns / 1ps

module sqrt_tb ();
	
    parameter CLK_PERIOD = 2;
    parameter WIDTH = 32;
    parameter FBITS = 16;
    parameter SF = 2.0**-16.0;  // Q8.8 scaling factor is 2^-8

    logic clk;
    logic start;             // start signal
    logic done;             // root and rem are valid
    logic [WIDTH-1:0] rad;   // radicand
    logic [WIDTH-1:0] root;  // root
    logic [WIDTH-1:0] rem;   // remainder

    sqrt #(.WIDTH(WIDTH), .FBITS(FBITS)) sqrt_inst (.*);

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d:\tsqrt(%f) = %b (%f) (rem = %b) (V=%b)",
                    $time, $itor(rad*SF), root, $itor(root*SF), rem, done);
    end

    initial begin
                clk = 1;

        #100    rad = 32'b0000_0000_1110_1000_1001_0000_0000_0000;  // 232.56250000
                start = 1;
        #10     start = 0;

        #120    rad = 32'b0000_0000_0000_0000_0100_0000_0000_0000;  // 0.25
                start = 1;
        #10     start = 0;

        #120    rad = 32'b0000_0000_0000_0010_0000_0000_0000_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120;

        $stop;
    end
	
	
endmodule