module draw_lines #(
    parameter DRAW_WIDTH = 320,
    parameter DRAW_HEIGHT = 240,
    parameter DRAW_SIZE = DRAW_WIDTH * DRAW_HEIGHT,
    parameter DRAW_ADDRW = $clog2(DRAW_SIZE),
    parameter DRAW_DATAW = 1,
    parameter FIELD_WIDTH = 8,
    parameter FIELD_HEIGHT = 6,
    parameter FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT,
    parameter FIELD_DATAW = 96,  // xn, yn, mag
    parameter FIELD_ADDRW = $clog2(FIELD_SIZE),
    parameter FIELD_SCALE = DRAW_WIDTH / FIELD_WIDTH
) (
    input logic clk,
    input logic start,
    output logic done,
    input logic [FIELD_ADDRW-1:0] field_addr_write,
    input logic [FIELD_DATAW-1:0] field_data_in,
    output logic [DRAW_ADDRW-1:0] draw_addr_write,
    output logic [DRAW_DATAW-1:0] draw_data_in
);
  //   logic [31:0] xi, yi, xn, yn;
  //   logic donenorm, startnorm;

  //   norm norm_inst (
  //       .x(xi),
  //       .y(yi),
  //       .clk(clk),
  //       .start(startnorm),
  //       .xn(),
  //       .yn(divisor),
  //       .done(done1)
  //   );

  logic [FIELD_DATAW-1:0] field_data_out;
  logic [FIELD_ADDRW-1:0] field_addr_read;

  bram_sdp #(
      .WIDTH(FIELD_DATAW),
      .DEPTH(FIELD_SIZE)
  ) bram_vel_inst (
      .clk_write(clk),
      .clk_read(clk),
      .we(1'b1),
      .addr_write(field_addr_write),
      .addr_read(field_addr_read),
      .data_in(field_data_in),
      .data_out(field_data_out)
  );

  enum {
    IDLE,
    CHECK_PIXEL,
    CHANGE_PIXEL
  } state;

  logic [15:0] x, y;
  logic [15:0] field_x, field_y;  // field x, field y
  logic on_line;

  pixel_on_line pixel_on_line_inst (
      .x({x, 16'b0}),
      .y({y, 16'b0}),
      .x0({field_x * FIELD_SCALE, 16'b0}),
      .y0({field_y * FIELD_SCALE, 16'b0}),
      .xn(field_data_out[95:64]),
      .yn(field_data_out[63:32]),
      .mag(field_data_out[31:0]),
      .on_line(on_line)
  );

  assign draw_addr_write = x + y * DRAW_WIDTH;
  assign field_addr_read = field_x + field_y * FIELD_WIDTH;





  always_ff @(posedge clk) begin
    done <= 0;
    case (state)
      CHECK_PIXEL: begin
        if (on_line) begin
          draw_data_in <= 1;
        end
        if (field_x == FIELD_WIDTH - 1) begin
          field_x <= 0;
          if (field_y == FIELD_HEIGHT - 1) begin
            field_y <= 0;
            state   <= CHANGE_PIXEL;
          end else begin
            field_y <= field_y + 1;
          end
        end else begin
          field_x <= field_x + 1;
        end
      end
      CHANGE_PIXEL: begin
        draw_data_in = 0;
        if (x == DRAW_WIDTH - 1) begin
          x <= 0;
          if (y == DRAW_HEIGHT - 1) begin
            y <= 0;
            state <= IDLE;
            done <= 1;
          end else begin
            y <= y + 1;
            state <= CHECK_PIXEL;
          end
        end else begin
          x <= x + 1;
          state <= CHECK_PIXEL;
        end
      end
      default: begin
        if (start) begin
          state <= CHECK_PIXEL;
          x <= 0;
          y <= 0;
          field_x <= 0;
          field_y <= 0;
        end
      end
    endcase
  end

endmodule
