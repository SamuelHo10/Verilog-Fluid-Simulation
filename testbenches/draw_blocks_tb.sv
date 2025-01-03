`timescale 1ns / 1ps


module draw_blocks_tb ();

  // Parameters
  parameter DRAW_WIDTH = 640;
  parameter DRAW_HEIGHT = 480;
  parameter DRAW_SIZE = DRAW_WIDTH * DRAW_HEIGHT;
  parameter FIELD_WIDTH = 8;
  parameter FIELD_HEIGHT = 6;
  parameter FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT;
  parameter FIELD_DATAW = 96;  // xn, yn, mag
  parameter FIELD_ADDRW = $clog2(FIELD_SIZE);
  parameter BLOCK_SIZE = DRAW_WIDTH / FIELD_WIDTH;
  parameter DRAW_ADDRW = $clog2(DRAW_SIZE);
  parameter DRAW_DATAW = 1;

  // Inputs
  logic clk;
  logic start;
  logic [FIELD_ADDRW-1:0] field_addr_write;
  logic [FIELD_DATAW-1:0] field_data_in;

  // Outputs
  logic done;
  logic [DRAW_ADDRW-1:0] draw_addr_write;
  logic [DRAW_DATAW-1:0] draw_data_in;

  // Instantiate the Unit Under Test (UUT)
  draw_blocks #(
      .DRAW_WIDTH  (DRAW_WIDTH),
      .DRAW_HEIGHT (DRAW_HEIGHT),
      .FIELD_WIDTH (FIELD_WIDTH),
      .FIELD_HEIGHT(FIELD_HEIGHT),
      .FIELD_SIZE  (FIELD_SIZE),
      .FIELD_DATAW (FIELD_DATAW),
      .FIELD_ADDRW (FIELD_ADDRW),
      .BLOCK_SIZE  (BLOCK_SIZE)
  ) draw_blocks_inst (
      .clk(clk),
      .start(start),
      .done(done),
      .field_addr_write(field_addr_write),
      .field_data_in(field_data_in),
      .draw_addr_write(draw_addr_write),
      .draw_data_in(draw_data_in),
      .draw_we(draw_we)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Stimulus
  initial begin
    // Initialize Inputs
    start = 0;
    field_addr_write = 0;
    field_data_in = 0;

    // Wait for global reset
    #100;

    // Start the draw_lines process
    start = 1;
    #10;
    start = 0;

    // Wait for the process to complete
    wait (done);

    // Finish simulation
    $stop;
  end

endmodule
