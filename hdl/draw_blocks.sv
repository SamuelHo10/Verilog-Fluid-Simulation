module draw_blocks #(
    parameter DRAW_WIDTH = 640,
    parameter DRAW_HEIGHT = 480,
    parameter DRAW_SIZE = DRAW_WIDTH * DRAW_HEIGHT,
    parameter DRAW_ADDRW = $clog2(DRAW_SIZE),
    parameter DRAW_DATAW = 1,
    parameter FIELD_WIDTH = 8,
    parameter FIELD_HEIGHT = 6,
    parameter FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT,
    parameter FIELD_DATAW = 96,  // xn, yn, mag
    parameter FIELD_ADDRW = $clog2(FIELD_SIZE),
    parameter BLOCK_SIZE = DRAW_WIDTH / FIELD_WIDTH
) (
    input logic clk,
    input logic start,
    output logic done,
    input logic [FIELD_ADDRW-1:0] field_addr_write,
    input logic [FIELD_DATAW-1:0] field_data_in,
    output logic [DRAW_ADDRW-1:0] draw_addr_write,
    output logic [DRAW_DATAW-1:0] draw_data_in,
    output logic draw_we
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

  logic start_draw_block, done_draw_block;
  logic [31:0] block_x, block_y;
  logic [15:0] block_x_int, block_y_int;

  logic [FIELD_DATAW-1:0] field_data_out;
  logic [FIELD_ADDRW-1:0] field_addr_read;

  bram_sdp #(
      .WIDTH (FIELD_DATAW),
      .DEPTH (FIELD_SIZE),
      .INIT_F("blocks.mem")
  ) bram_field_inst (
      .clk_write(clk),
      .clk_read(clk),
      .we(1'b0),
      .addr_write(field_addr_write),
      .addr_read(field_addr_read),
      .data_in(field_data_in),
      .data_out(field_data_out)
  );

  enum {
    IDLE,
    DRAW,
    CHANGE_BLOCK
  } state;

  draw_block #(
      .DRAW_WIDTH (DRAW_WIDTH),
      .DRAW_HEIGHT(DRAW_HEIGHT),
      .DRAW_SIZE  (DRAW_SIZE),
      .DRAW_ADDRW (DRAW_ADDRW),
      .DRAW_DATAW (DRAW_DATAW),
      .BLOCK_SIZE (DRAW_WIDTH / FIELD_WIDTH)
  ) draw_block_inst (
      .clk(clk),
      .start(start_draw_block),
      .done(done_draw_block),
      .block_x(block_x),
      .block_y(block_y),
      .xn(field_data_out[95:64]),
      .yn(field_data_out[63:32]),
      .mag(field_data_out[31:0]),
      .draw_addr_write(draw_addr_write),
      .draw_data_in(draw_data_in),
      .draw_we(draw_we)
  );


  assign block_x = {block_x_int, 16'b0};
  assign block_y = {block_y_int, 16'b0};


  always_ff @(posedge clk) begin
    done <= 0;
    start_draw_block <= 0;
    case (state)
      DRAW: begin
        if (done_draw_block) begin
          state <= CHANGE_BLOCK;
        end
      end
      CHANGE_BLOCK: begin
        state <= DRAW;
        start_draw_block <= 1;
        field_addr_read <= field_addr_read + 1;
        block_x_int <= block_x_int + BLOCK_SIZE;
        if (block_x_int == (FIELD_WIDTH - 1) * BLOCK_SIZE) begin
          block_x_int <= 0;
          block_y_int <= block_y_int + BLOCK_SIZE;
          if (block_y_int == (FIELD_HEIGHT - 1) * BLOCK_SIZE) begin
            block_y_int <= 0;
            field_addr_read <= 0;
            state <= IDLE;
            done <= 1;
          end
        end
      end
      default: begin
        if (start) begin
          state <= DRAW;
          block_x_int <= 0;
          block_y_int <= 0;
          field_addr_read <= 0;
          start_draw_block <= 1;
        end
      end
    endcase
  end

endmodule
