`timescale 1ns / 1ps

module div_tb ();

  parameter CLK_PERIOD = 2;
  parameter WIDTH = 32;
  parameter SF = 2.0 ** -16.0;

  logic [WIDTH-1:0] n;  // Numerator
  logic [WIDTH-1:0] d;  // Denominator
  logic start;
  logic clk;
  logic [WIDTH-1:0] q;  // Quotient
  logic [WIDTH-1:0] r;  // Remainder
  logic done;

  div #(.WIDTH(WIDTH)) div_inst (.*);

  always #(CLK_PERIOD / 2) clk = ~clk;

  initial begin
    $monitor("\t%d:\t N = %f, D = %f, Q = %f, R = %f, done = %b", $time, $itor($signed(n) * SF),
             $itor($signed(d) * SF), $itor($signed(q) * SF), $itor(r * SF), done);
  end

  initial begin
    clk = 1;
    for (int i = 0; i < 5; i++) begin

      n = $urandom_range(0, 100/SF) * -1 ** $urandom_range(0, 1);
      d = $urandom_range(0, 10/SF)* -1 ** $urandom_range(0, 1);
      start = 1;
      #10 start = 0;
      #100;

    end



    $stop;
  end


endmodule
