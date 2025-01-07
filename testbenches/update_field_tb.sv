`timescale 1ns / 1ps

module update_field_tb ();

  // Parameters
  localparam FIELD_WIDTH = 8;
  localparam FIELD_HEIGHT = 6;
  localparam FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT;
  localparam FIELD_DATAW = 96;  // xn, yn, mag
  localparam FIELD_ADDRW = $clog2(FIELD_SIZE);

  // Inputs
  logic clk;
  logic reset;
  logic start;
  // Outputs
  logic done;
  logic [FIELD_DATAW-1:0] field_data_in;
  logic [FIELD_ADDRW-1:0] field_addr_write;
  logic field_we;

  // Instantiate the Unit Under Test (UUT)
  update_field #(
      .FIELD_WIDTH(FIELD_WIDTH),
      .FIELD_HEIGHT(FIELD_HEIGHT),
      .FIELD_DATAW(FIELD_DATAW)
  ) uut (
      .clk(clk),
      .start(start),
      .done(done),
      .field_data_in(field_data_in),
      .field_addr_write(field_addr_write),
      .field_we(field_we)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin

    for (int i = 0; i < 100; i++) begin
      #10;
      start = 1;
      #10;
      start = 0;
      wait (done);
    end

    #100;

    $stop;
  end

endmodule
