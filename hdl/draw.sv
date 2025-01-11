module draw #(
    parameter DRAW_WIDTH  = 640,
    parameter DRAW_HEIGHT = 480,
    parameter DRAW_SIZE   = DRAW_WIDTH * DRAW_HEIGHT,
    parameter DRAW_ADDRW  = $clog2(DRAW_SIZE),
    parameter DRAW_DATAW  = 1
) (
    input logic clk,
    input logic vga_clk,
    input logic [DRAW_ADDRW-1:0] draw_addr_write,
    input logic [DRAW_DATAW-1:0] draw_data_in,
    input logic draw_we,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs,
    input logic [15:0] cursor_x,
    input logic [15:0] cursor_y
);

  localparam CURSOR_SIZE = 5;

  logic h_sync, v_sync;
  logic disp_ena;

  logic [DRAW_ADDRW-1:0] draw_addr_read;
  logic [9:0] col, row;
  logic [DRAW_DATAW-1:0] draw_data_out;

  bram_sdp #(
      .WIDTH(DRAW_DATAW),
      .DEPTH(DRAW_SIZE)    //,
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

  logic [15:0] start_cursor_x, start_cursor_y;
  logic [15:0] end_cursor_x, end_cursor_y;

  assign start_cursor_x = cursor_x > CURSOR_SIZE ? cursor_x - CURSOR_SIZE : 0;
  assign start_cursor_y = cursor_y > CURSOR_SIZE ? cursor_y - CURSOR_SIZE : 0;
  assign end_cursor_x = cursor_x + CURSOR_SIZE < DRAW_WIDTH ? cursor_x + CURSOR_SIZE : DRAW_WIDTH;
  assign end_cursor_y = cursor_y + CURSOR_SIZE < DRAW_HEIGHT ? cursor_y + CURSOR_SIZE : DRAW_HEIGHT;



  always @(posedge vga_clk) begin
    if (disp_ena) begin
      if (col > start_cursor_x && col < end_cursor_x && row > start_cursor_y && row < end_cursor_y) begin
        {vga_r, vga_g, vga_b} <= 12'b1111_0000_0000;
      end else if (draw_data_out == 2'b1) begin
        {vga_r, vga_g, vga_b} <= 12'b1111_1111_1111;
      end else begin
        {vga_r, vga_g, vga_b} <= 12'b0000_0000_0000;
      end
    end else begin
      {vga_r, vga_g, vga_b} <= 0;
    end

    vga_hs <= h_sync;
    vga_vs <= v_sync;
  end

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
