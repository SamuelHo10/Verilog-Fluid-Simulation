// Draws arrow for a block
module draw_block #(
    parameter DRAW_WIDTH  = 320,
    parameter DRAW_HEIGHT = 240,
    parameter DRAW_SIZE   = DRAW_WIDTH * DRAW_HEIGHT,
    parameter DRAW_ADDRW  = $clog2(DRAW_SIZE),
    parameter DRAW_DATAW  = 1,
    parameter BLOCK_SIZE  = 40
) (
    input logic clk,
    input logic start,
    output logic done,
    input logic [31:0] block_x,
    input logic [31:0] block_y,
    input logic [31:0] xn,
    input logic [31:0] yn,
    input logic [31:0] mag,
    output logic [DRAW_ADDRW-1:0] draw_addr_write,
    output logic [DRAW_DATAW-1:0] draw_data_in,
    output logic draw_we
);


  enum {
    IDLE,
    DRAW
  } state;

  logic [15:0] x, y;
  logic [31:0] x0, y0, x_decimal, y_decimal;
  logic [64:0] xn_mult, yn_mult, y_addr_mult;
  logic [64:0] draw_addr_write_decimal;

  assign xn_mult = xn * (mag>>1);
  assign yn_mult = yn * (mag>>1);
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
      .on_line(draw_data_in)
  );
  
  assign y_addr_mult = (y_decimal + block_y) * {DRAW_WIDTH, 16'b0};
  assign draw_addr_write_decimal = {16'b0, x_decimal + block_x, 16'b0} + y_addr_mult;
  assign draw_addr_write = draw_addr_write_decimal[DRAW_ADDRW + 31:32];

  always_ff @(posedge clk) begin
    done <= 0;
    case (state)
      DRAW: begin
        x <= x + 1;
        if (x == BLOCK_SIZE - 1) begin
          x <= 0;
          y <= y + 1;
          if (y == BLOCK_SIZE - 1) begin
            y <= 0;
            state <= IDLE;
            done <= 1;
            draw_we <= 0;
          end
        end
      end
      default: begin
        draw_we <= 0;
        if (start) begin
          state <= DRAW;
          x <= 0;
          y <= 0;
          draw_we <= 1;
        end
      end
    endcase
  end

endmodule