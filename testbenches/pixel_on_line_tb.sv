// FILE: hdl/test_pixel_on_line.sv
`timescale 1ns / 1ps

module pixel_on_line_tb ();

  // Parameters
  localparam LINE_WIDTH_SQR = 100;
  parameter SF = 2.0 ** -16.0;


  // Inputs
  logic signed [31:0] x;
  logic signed [31:0] y;
  logic signed [31:0] x0;
  logic signed [31:0] y0;
  logic signed [31:0] xn;
  logic signed [31:0] yn;
  logic signed [31:0] mag;

  // Outputs
  logic on_line;

  // Instantiate the Unit Under Test (UUT)
  pixel_on_line #(
      .LINE_WIDTH_SQR(LINE_WIDTH_SQR)
  ) uut (
      .x(x),
      .y(y),
      .x0(x0),
      .y0(y0),
      .xn(xn),
      .yn(yn),
      .mag(mag),
      .on_line(on_line)
  );

  // Test stimulus
  initial begin

    x   = 5/SF;
    y   = 10/SF;
    x0  = 0/SF;
    y0  = 0/SF;
    xn  = $sqrt(2)/2/SF;
    yn  = $sqrt(2)/2/SF;
    mag = 20/SF;
    #5;
    $display("on_line = %b", on_line);
    #5;

    x   = 10/SF;
    y   = 10/SF;
    x0  = 0/SF;
    y0  = 0/SF;
    xn  = $sqrt(2)/2/SF;
    yn  = $sqrt(2)/2/SF;
    mag = 30/SF;
    #5;
    $display("on_line = %b", on_line);
    #5;



    $stop;
  end

endmodule
