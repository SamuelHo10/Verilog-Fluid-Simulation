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

  logic start_draw_block;

  logic [FIELD_DATAW-1:0] field_data_out;
  logic [FIELD_ADDRW-1:0] field_addr_read;

  bram_sdp #(
      .WIDTH(FIELD_DATAW),
      .DEPTH(FIELD_SIZE),
      .INIT_F("blocks.mem")
  ) bram_vel_inst (
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

  
  assign draw_addr_write = x + y * DRAW_WIDTH;
  assign field_addr_read = field_x + field_y * FIELD_WIDTH;


  draw_block #(
      .DRAW_WIDTH (DRAW_WIDTH),
      .DRAW_HEIGHT(DRAW_HEIGHT),
      .DRAW_SIZE  (DRAW_SIZE),
      .DRAW_ADDRW (DRAW_ADDRW),
      .DRAW_DATAW (DRAW_DATAW),
      .BLOCK_SIZE (DRAW_WIDTH / FIELD_WIDTH)
  ) draw_block_inst (
      .clk(MAX10_CLK1_50),
      .start(start_draw_block),
      .done(),
      .block_x({16'd40, 16'b0}),
      .block_y({16'd40, 16'b0}),
      .xn({16'b0, 16'b1011010011111101}),
      .yn({16'b0, 16'b1011010011111101}),
      .mag({16'd20, 16'b0}),
      .draw_addr_write(draw_addr_write),
      .draw_data_in(draw_data_in),
      .draw_we(draw_we)
  );


  always_ff @(posedge clk) begin
    done <= 0;
    case (state)
      DRAW: begin
        if begin

        end
      end
      default: begin
        if (start) begin
          state <= CHECK_PIXEL;
          field_x <= 0;
          field_y <= 0;
          field_addr_read <= 0;
        end
      end
    endcase
  end

endmodule
