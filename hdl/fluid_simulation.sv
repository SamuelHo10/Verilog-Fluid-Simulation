
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

   localparam FIELD_WIDTH = 80;
   localparam FIELD_HEIGHT = 60;
   localparam FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT;
   localparam FIELD_DATAW = 96; // xn, yn, mag
   localparam FIELD_ADDRW = $clog2(FIELD_SIZE);


   logic [FIELD_ADDRW-1:0] field_addr_write, field_addr_read;
   logic [FIELD_DATAW-1:0] field_data_in, field_data_out;

   bram_sdp bram_vel_inst # (
      .WIDTH(FIELD_DATAW),
      .DEPTH(FIELD_SIZE),
      .INIT_F("vel_init.mem")
   ) (
      .clk_write(MAX10_CLK1_50),
      .clk_read(MAX10_CLK1_50),
      .we(1'b1),
      .addr_write(field_addr_write),
      .addr_read(field_addr_read),
      .data_in(field_data_in),
      .data_out(field_data_out)
   );

      

  draw draw_inst #(
      .FIELD_DATAW(FIELD_DATAW)
  ) (
      .clk(MAX10_CLK1_50),
      .vga_r(VGA_R),
      .vga_g(VGA_G),
      .vga_b(VGA_B),
      .vga_hs(VGA_HS),
      .vga_vs(VGA_VS),
      .field_addr_read(field_addr_read),
      .field_data_out(field_data_out)
  );








endmodule

