
module fluid_simulation (
    input  logic       ADC_CLK_10,
    input  logic       MAX10_CLK1_50,
    input  logic       MAX10_CLK2_50,
    output logic [3:0] VGA_R,
    output logic [3:0] VGA_G,
    output logic [3:0] VGA_B,
    output logic       VGA_HS,
    output logic       VGA_VS,
    input  logic [1:0] KEY,
    input  logic [9:0] SW,
    output logic [9:0] LEDR,
    output logic [7:0] HEX0,
    output logic [7:0] HEX1,
    output logic [7:0] HEX2,
    output logic [7:0] HEX3,
    output logic [7:0] HEX4,
    output logic [7:0] HEX5
);

  localparam DRAW_WIDTH = 320;
  localparam DRAW_HEIGHT = 240;
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
  
  logic start_draw_lines;



  draw_lines #(
      .DRAW_WIDTH(DRAW_WIDTH),
      .DRAW_HEIGHT(DRAW_HEIGHT),
      .DRAW_SIZE(DRAW_SIZE),
      .DRAW_ADDRW(DRAW_ADDRW),
      .DRAW_DATAW(DRAW_DATAW),
      .FIELD_WIDTH(FIELD_WIDTH),
      .FIELD_HEIGHT(FIELD_HEIGHT),
      .FIELD_SIZE(FIELD_SIZE),
      .FIELD_DATAW(FIELD_DATAW),
      .FIELD_ADDRW(FIELD_ADDRW)
  ) draw_lines_inst (
      .clk(MAX10_CLK1_50),
      .start(start_draw_lines),
      .done(),
      .field_addr_write(field_addr_write),
      .field_data_in(field_data_in),
      .draw_addr_write(draw_addr_write),
      .draw_data_in(draw_data_in)
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
      .draw_data_in(draw_data_in)
  );


  enum {
    IDLE,
    RUNNING
  } state;

  always_ff @(posedge MAX10_CLK1_50) begin
    case (state)
      RUNNING: begin

      end
      default: begin
        if (KEY[0]) begin
          state <= RUNNING;
          start_draw_lines <= 1;
          field_addr_write <= 0;
          field_data_in <= {32'd46341, 32'd46341, 32'd50 << 16};
        end
      end
    endcase
  end
endmodule

