`timescale 1ns / 1ps

module draw_block_tb ();

  parameter CLK_PERIOD = 2;
  parameter DRAW_WIDTH = 320;
  parameter DRAW_HEIGHT = 240;
  parameter DRAW_ADDRW = $clog2(DRAW_WIDTH * DRAW_HEIGHT);
  parameter DRAW_DATAW = 1;
  parameter SF = 2.0 ** -16.0;


  logic clk;
  logic start;
  logic [31:0] block_x;
  logic [31:0] block_y;
  logic [31:0] xn;
  logic [31:0] yn;
  logic [31:0] mag;

  // Outputs
  logic [DRAW_ADDRW-1:0] draw_addr_write;
  logic [DRAW_DATAW-1:0] draw_data_in;
  logic draw_we;

  draw_block #(
      .DRAW_WIDTH (DRAW_WIDTH),
      .DRAW_HEIGHT(DRAW_HEIGHT),
      .DRAW_ADDRW (DRAW_ADDRW),
      .DRAW_DATAW (DRAW_DATAW)
  ) uut (
      .clk(clk),
      .start(start),
      .block_x(block_x),
      .block_y(block_y),
      .xn(xn),
      .yn(yn),
      .mag(mag),
      .draw_addr_write(draw_addr_write),
      .draw_data_in(draw_data_in),
      .draw_we(draw_we)
  );

  always #(CLK_PERIOD / 2) clk = ~clk;

  initial begin
    // Initialize Inputs
    start = 0;
    block_x = 0;
    block_y = 0;
    xn = 0;
    yn = 0;
    mag = 0;
    clk = 1;
    #100;

    block_x = 40/SF;
    block_y = 40/SF;
    xn = 0;
    yn = 1/SF;
    mag = 10/SF;

    start = 1;
    #10;
    start = 0;

    #4000;

    $stop;
  end


endmodule
