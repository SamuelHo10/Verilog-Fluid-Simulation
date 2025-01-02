
module fluid_simulation (
    //////////// CLOCK //////////
    input ADC_CLK_10,
    input MAX10_CLK1_50,
    input MAX10_CLK2_50,

    //////////// SEG7 //////////
    output [7:0] HEX0,
    output [7:0] HEX1,
    output [7:0] HEX2,
    output [7:0] HEX3,
    output [7:0] HEX4,
    output [7:0] HEX5,

    //////////// KEY //////////
    input [1:0] KEY,

    //////////// VGA //////////
    output [3:0] VGA_B,
    output [3:0] VGA_G,
    output       VGA_HS,
    output [3:0] VGA_R,
    output       VGA_VS,

    //////////// Accelerometer //////////
    output       GSENSOR_CS_N,
    input  [2:1] GSENSOR_INT,
    output       GSENSOR_SCLK,
    inout        GSENSOR_SDI,
    inout        GSENSOR_SDO
);

  localparam DRAW_WIDTH = 640;
  localparam DRAW_HEIGHT = 480;
  localparam DRAW_SIZE = DRAW_WIDTH * DRAW_HEIGHT;
  localparam DRAW_ADDRW = $clog2(DRAW_SIZE);
  localparam DRAW_DATAW = 1;

  localparam FIELD_WIDTH = 8;
  localparam FIELD_HEIGHT = 6;
  localparam FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT;
  localparam FIELD_DATAW = 96;  // xn, yn, mag
  localparam FIELD_ADDRW = $clog2(FIELD_SIZE);


  logic [FIELD_ADDRW-1:0] field_addr_write, field_addr_read;
  logic [FIELD_DATAW-1:0] field_data_in, field_data_out;


  logic [DRAW_ADDRW-1:0] draw_addr_write;
  logic [DRAW_DATAW-1:0] draw_data_in;
  logic start_draw_block, draw_we;



  // draw_lines #(
  //     .DRAW_WIDTH(DRAW_WIDTH),
  //     .DRAW_HEIGHT(DRAW_HEIGHT),
  //     .DRAW_SIZE(DRAW_SIZE),
  //     .DRAW_ADDRW(DRAW_ADDRW),
  //     .DRAW_DATAW(DRAW_DATAW),
  //     .FIELD_WIDTH(FIELD_WIDTH),
  //     .FIELD_HEIGHT(FIELD_HEIGHT),
  //     .FIELD_SIZE(FIELD_SIZE),
  //     .FIELD_DATAW(FIELD_DATAW),
  //     .FIELD_ADDRW(FIELD_ADDRW)
  // ) draw_lines_inst (
  //     .clk(MAX10_CLK1_50),
  //     .start(start_draw_lines),
  //     .done(),
  //     .field_addr_write(field_addr_write),
  //     .field_data_in(field_data_in),
  //     .draw_addr_write(draw_addr_write),
  //     .draw_data_in(draw_data_in)
  // );

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


  draw #(
      .DRAW_WIDTH (DRAW_WIDTH),
      .DRAW_HEIGHT(DRAW_HEIGHT),
      .DRAW_SIZE  (DRAW_SIZE),
      .DRAW_ADDRW (DRAW_ADDRW),
      .DRAW_DATAW (DRAW_DATAW)
  ) draw_inst (
      .clk(MAX10_CLK1_50),
      .vga_r(VGA_R),
      .vga_g(VGA_G),
      .vga_b(VGA_B),
      .vga_hs(VGA_HS),
      .vga_vs(VGA_VS),
      .draw_addr_write(draw_addr_write),
      .draw_data_in(draw_data_in),
      .draw_we(draw_we)
  );

  assign start_draw_block = ~KEY[0];

  // enum {
  //   IDLE,
  //   RUNNING
  // } state;

  // always_ff @(posedge MAX10_CLK1_50) begin
  //   case (state)
  //     RUNNING: begin
  //       start_draw_block <= 0;
  //       temp2 <= 0;
  //     end
  //     default: begin
  //       start_draw_block <= 0;
  //       if (KEY[0]) begin
  //         state <= RUNNING;
  //         start_draw_block <= 1;
  //         temp1 <= 0;
  //       end
  //     end
  //   endcase
  // end
endmodule

