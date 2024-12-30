module draw #(
    parameter line_width  = 4,
    parameter FIELD_DATAW = 96
) (
    input logic clk,
    input logic field_addr_read,
    input logic [FIELD_DATAW-1:0] field_data_out,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs
);

  logic h_sync, v_sync;
  logic disp_ena;
  logic vga_clk;

  localparam DRAW_WIDTH = 320;
  localparam DRAW_HEIGHT = 240;
  localparam DRAW_SIZE = DRAW_WIDTH * DRAW_HEIGHT;
  localparam DRAW_ADDRW = $clog2(DRAW_SIZE);
  localparam DRAW_DATAW = 1;

  logic [DRAW_ADDRW-1:0] draw_addr_write, draw_addr_read;
  logic [9:0] col, row;
  logic [DRAW_DATAW-1:0] draw_data_in, draw_data_out;

  bram_sdp #(
      .WIDTH (DRAW_DATAW),
      .DEPTH (DRAW_SIZE)
  ) bram_draw_inst (
      .clk_write(clk),
      .clk_read(vga_clk),
      .we(1'b1),
      .addr_write(draw_addr_write),
      .addr_read(draw_addr_read),
      .data_in(draw_data_in),
      .data_out(draw_data_out)
  );

  assign draw_addr_read = (col >> 1) + (row >> 1) * DRAW_WIDTH;

  always @(posedge vga_clk) begin
    {vga_r, vga_g, vga_b} <= disp_ena ? {12{draw_data_out}} : 0;
    vga_hs <= h_sync;
    vga_vs <= v_sync;
  end

  // Instantiate PLL to convert the 50 MHz clock to a 25 MHz clock for timing.
  pll vgapll_inst (
      .inclk0(clk),
      .c0    (vga_clk)
  );

  // Instantite VGA controller
  vga_controller vga_controller_inst (
      .pixel_clk(vga_clk),
      .reset_n  (1'b1),
      .h_sync   (h_sync),
      .v_sync   (v_sync),
      .disp_ena (disp_ena),
      .col     (col),
      .row     (row)
  );

endmodule
