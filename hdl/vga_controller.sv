// Definitely do not modify this file
//
// 2018/02/05 Compiled by M. Hildebrand from various sources

module vga_controller #(
    parameter H_PIXELS = 640,   // horizontal display
    parameter H_FP     = 16,    // horizontal Front Porch
    parameter H_PULSE  = 96,    // horizontal sync pulse
    parameter H_BP     = 48,    // horizontal back porch
    parameter H_POL    = 1'b0,  // horizontal sync polarity (1 = positive, 0 = negative)
    parameter V_PIXELS = 480,   // vertical display
    parameter V_FP     = 10,    // vertical front porch
    parameter V_PULSE  = 2,     // vertical pulse
    parameter V_BP     = 33,    // vertical back porch
    parameter V_POL    = 1'b0,   // vertical sync polarity (1 = positive, 0 = negative)
    parameter ADDR_SIZE = $clog2(H_PIXELS * V_PIXELS)
) (
    input      pixel_clk,  // Pixel clock
    input      reset_n,    // Active low synchronous reset
    output reg h_sync,     // horizontal sync signal
    output reg v_sync,     // vertical sync signal
    output reg disp_ena,   // display enable (0 = all colors must be blank)
    output reg [ADDR_SIZE:0] addr, // current column
    output reg [9:0] col,  // current column
    output reg [9:0] row   // current row
);

  // Get total number of row and column pixel clocks
  localparam H_PERIOD = H_PULSE + H_BP + H_PIXELS + H_FP;
  localparam V_PERIOD = V_PULSE + V_BP + V_PIXELS + V_FP;

  // Full range counters
  reg [$clog2(H_PERIOD)-1:0] h_count;
  reg [$clog2(V_PERIOD)-1:0] v_count;

  always @(posedge pixel_clk) begin

    if (reset_n == 1'b0) begin
      h_count <= 0;
      v_count <= 0;
      h_sync <= ~H_POL;
      v_sync <= ~V_POL;
      disp_ena <= 1'b0;
      addr <= 0;
      col <= 0;
      row <= 0;
    end else begin

      // Pixel Counters
      if (h_count < H_PERIOD - 1) begin
        h_count <= h_count + 1;
      end else begin
        h_count <= 0;
        if (v_count < V_PERIOD - 1) begin
          v_count <= v_count + 1;
        end else begin
          v_count <= 0;
          addr <= 0;
        end
      end

      // Horizontal Sync Signal
      if ((h_count < H_PIXELS + H_FP) || (h_count > H_PIXELS + H_FP + H_PULSE)) begin
        h_sync <= ~H_POL;
      end else begin
        h_sync <= H_POL;
      end

      // Vertical Sync Signal
      if ((v_count < V_PIXELS + V_FP) || (v_count > V_PIXELS + V_FP + V_PULSE)) begin
        v_sync <= ~V_POL;
      end else begin
        v_sync <= V_POL;
      end

      if (h_count < H_PIXELS) begin
        col <= h_count;
      end

      if (v_count < V_PIXELS) begin
        row <= v_count;
      end

      // Set display enable output
      if (h_count < H_PIXELS && v_count < V_PIXELS) begin
        disp_ena <= 1'b1;
        addr <= addr + 1;
      end else begin
        disp_ena <= 1'b0;
      end
    end
  end

endmodule
