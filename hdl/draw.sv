module draw #(
    parameter DRAW_WIDTH  = 640,
    parameter DRAW_HEIGHT = 480,
    parameter DRAW_SIZE   = DRAW_WIDTH * DRAW_HEIGHT,
    parameter DRAW_ADDRW  = $clog2(DRAW_SIZE),
    parameter DRAW_DATAW  = 1
) (
    input logic clk,
    input logic [DRAW_ADDRW-1:0] draw_addr_write,
    input logic [DRAW_DATAW-1:0] draw_data_in,
    input logic draw_we,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs
);

  logic h_sync, v_sync;
  logic disp_ena;
  logic vga_clk;

  logic [DRAW_ADDRW-1:0] draw_addr_read;
  logic [9:0] col, row;
  logic [DRAW_DATAW-1:0] draw_data_out;

  bram_sdp #(
      .WIDTH (DRAW_DATAW),
      .DEPTH (DRAW_SIZE)//,
      //.INIT_F("cheetah.mem")
  ) bram_draw_inst (
      .clk_write(clk),
      .clk_read(vga_clk),
      .we(draw_we),
      .addr_write(draw_addr_write),
      .addr_read(draw_addr_read),
      .data_in(draw_data_in),
      .data_out(draw_data_out)
  );


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
      .addr     (draw_addr_read),
      .col      (col),
      .row      (row)
  );

endmodule
