module draw #(
    parameter line_width = 4
	parameter FIELD_DATAW = 96
) (
    input logic clk,
	input logic field_addr_read,
	input logic [FIELD_DATAW-1:0] field_data_out,
	output logic [3:0] vga_r,
	output logic [3:0] vga_g,
	output logic [3:0] vga_b,
	output logic vga_hs,
	output logic vga_vs,
);

  logic [31:0] col, row;
  logic h_sync, v_sync;
  logic disp_ena;
  logic vga_clk;

  always @(posedge vga_clk) begin
    if (disp_ena == 1'b1) begin
      vga_r <= 4'd1;
      vga_g <= 4'd1;
      vga_b <= 4'd1;
    end else begin
      vga_r <= 4'd0;
      vga_g <= 4'd0;
      vga_b <= 4'd0;
    end
    vga_hs <= h_sync;
    vga_vs <= v_sync;
  end

  // Instantiate PLL to convert the 50 MHz clock to a 25 MHz clock for timing.
  pll vgapll_inst (
      .inclk0(clk),
      .c0    (vga_clk)
  );

  // Instantite VGA controller
  vga_controller control (
      .pixel_clk(vga_clk),
      .reset_n  (),
      .h_sync   (h_sync),
      .v_sync   (v_sync),
      .disp_ena (disp_ena),
      .column   (col),
      .row      (row)
  );

endmodule
