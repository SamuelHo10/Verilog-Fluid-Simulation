// Draws arrow for a block
module draw_block #(
    parameter DRAW_WIDTH  = 320,
    parameter DRAW_HEIGHT = 240,
    parameter DRAW_SIZE   = DRAW_WIDTH * DRAW_HEIGHT,
    parameter DRAW_ADDRW  = $clog2(DRAW_SIZE),
    parameter DRAW_DATAW  = 1,
    parameter BLOCK_SIZE  = 'd40
) (
    input logic clk,
    input logic start,
    output logic done,
    input logic [31:0] block_x,
    input logic [31:0] block_y,
    input logic signed [31:0] xn,
    input logic signed [31:0] yn,
    input logic signed [31:0] mag,
    output logic [DRAW_ADDRW-1:0] draw_addr_write,
    output logic [DRAW_DATAW-1:0] draw_data_in,
    output logic draw_we
);



  logic start_pixel_on_line;
  logic [15:0] x, y;
  logic [31:0] x0, y0, x_decimal, y_decimal;
  logic signed [64:0] xn_mult, yn_mult;
  logic [64:0] y_addr_mult, draw_addr_write_decimal;

  assign xn_mult = xn * (mag >> 1);
  assign yn_mult = yn * (mag >> 1);
  assign x_decimal = {x, 16'b0};
  assign y_decimal = {y, 16'b0};
  assign x0 = {BLOCK_SIZE, 15'b0} - xn_mult[47:16];
  assign y0 = {BLOCK_SIZE, 15'b0} - yn_mult[47:16];

  pixel_on_line pixel_on_line_inst (
      .x(x_decimal),
      .y(y_decimal),
      .x0(x0),
      .y0(y0),
      .xn(xn),
      .yn(yn),
      .mag(mag),
      .on_line(draw_data_in),
      .we(draw_we),
      .start(start_pixel_on_line),
      .clk(clk)
  );

  assign y_addr_mult = (y_decimal + block_y) * {DRAW_WIDTH, 16'b0};
  assign draw_addr_write_decimal = {16'b0, x_decimal + block_x, 16'b0} + y_addr_mult;
  assign draw_addr_write = draw_addr_write_decimal[DRAW_ADDRW+31:32];

  enum {
    IDLE,
    CHECK_PIXEL,
    CHANGE_PIXEL
  } state;

  always_ff @(posedge clk) begin
    done <= 0;
    case (state)
      CHECK_PIXEL: begin
        start_pixel_on_line <= 0;
        if (draw_we) begin
          state <= CHANGE_PIXEL;
        end
      end
      CHANGE_PIXEL: begin
        state <= CHECK_PIXEL;
        x <= x + 1;
        start_pixel_on_line <= 1;
        if (x == BLOCK_SIZE - 1) begin
          x <= 0;
          y <= y + 1;
          if (y == BLOCK_SIZE - 1) begin
            y <= 0;
            state <= IDLE;
            done <= 1;
            start_pixel_on_line <= 0;
          end
        end
      end
      default: begin
        if (start) begin
          state <= CHECK_PIXEL;
          x <= 0;
          y <= 0;
          start_pixel_on_line <= 1;
        end
      end
    endcase
  end

endmodule
