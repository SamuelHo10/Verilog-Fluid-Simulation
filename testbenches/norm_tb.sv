`timescale 1ns / 1ps

module norm_tb ();

  parameter CLK_PERIOD = 2;
  parameter WIDTH = 32;
  parameter SF = 2.0 ** -16.0;


  logic signed [31:0] x;
  logic signed [31:0] y;
  logic clk;
  logic start;
  logic signed [31:0] xn;
  logic signed [31:0] yn;
  logic done;

  norm norm_inst (.*);

  always #(CLK_PERIOD / 2) clk = ~clk;

  initial begin
    $monitor("\t%d:\t x = %f, y = %f, xn = %f, yn = %f, done = %b", $time, $itor($signed(x) * SF),
             $itor($signed(y) * SF), $itor($signed(xn) * SF), $itor($signed(yn) * SF), done);
  end

  initial begin
    clk = 1;
    for (int i = 0; i < 5; i++) begin

      x = $urandom_range(0, 100 / SF) * -1 ** $urandom_range(0, 1);
      y = $urandom_range(0, 100 / SF) * -1 ** $urandom_range(0, 1);
      start = 1;
      #10 start = 0;
      #300;

    end



    $stop;
  end


endmodule
