module cursor #(
    parameter DRAW_WIDTH  = 640,
    parameter DRAW_HEIGHT = 480,
    parameter BLOCK_SIZE  = 80
) (
    input  logic        clk,
    input  logic        spi_clk,
    input  logic        spi_clk_out,
    input  logic [ 1:0] KEY,
    output logic        GSENSOR_CS_N,
    input  logic [ 2:1] GSENSOR_INT,
    output logic        GSENSOR_SCLK,
    inout  logic        GSENSOR_SDI,
    inout  logic        GSENSOR_SDO,
    output logic [31:0] cursor_x = 0,
    output logic [31:0] cursor_y = 0,
    output logic [15:0] cursor_field_x,
    output logic [15:0] cursor_field_y,
    output logic [15:0] cursor_field_x_prev,
    output logic [15:0] cursor_field_y_prev
);

  localparam SPI_CLK_FREQ = 200;  // SPI Clock (Hz)
  localparam UPDATE_FREQ = 1;  // Sampling frequency (Hz)
  localparam THRESHOLD = 'sh50;
  localparam MOVEMENT_SPEED = 32'h00000001;
  localparam integer INV_BLOCK_SIZE = (2 ** 16) / BLOCK_SIZE;

  logic data_update;
  logic signed [15:0] data_x, data_y;
  logic [63:0] cursor_field_x_mult, cursor_field_y_mult;

  spi_control #(  // parameters
      .SPI_CLK_FREQ(SPI_CLK_FREQ),
      .UPDATE_FREQ (UPDATE_FREQ)
  ) spi_ctrl (  // port connections
      .reset_n    (1'b1),
      .clk        (clk),
      .spi_clk    (spi_clk),
      .spi_clk_out(spi_clk_out),
      .data_update(data_update),
      .data_x     (data_x),
      .data_y     (data_y),
      .SPI_SDI    (GSENSOR_SDI),
      .SPI_SDO    (GSENSOR_SDO),
      .SPI_CSN    (GSENSOR_CS_N),
      .SPI_CLK    (GSENSOR_SCLK),
      .interrupt  (GSENSOR_INT)
  );

  assign cursor_field_x_mult = cursor_x * INV_BLOCK_SIZE;
  assign cursor_field_y_mult = cursor_y * INV_BLOCK_SIZE;
  assign cursor_field_x      = cursor_field_x_mult[47:32];
  assign cursor_field_y      = cursor_field_y_mult[47:32];


  always_ff @(posedge clk) begin

    if (data_x > THRESHOLD) begin
      cursor_x <= cursor_x - MOVEMENT_SPEED;
    end else if (data_x < -THRESHOLD) begin
      cursor_x <= cursor_x + MOVEMENT_SPEED;
    end

    if (data_y > THRESHOLD) begin
      cursor_y <= cursor_y + MOVEMENT_SPEED;
    end else if (data_y < -THRESHOLD) begin
      cursor_y <= cursor_y - MOVEMENT_SPEED;
    end

    if (cursor_x[31:16] == DRAW_WIDTH) begin
      cursor_x <= {DRAW_WIDTH - 1, 16'b0};
    end else if (cursor_x[31:16] == 0) begin
      cursor_x <= {16'b1, 16'b0};
    end

    if (cursor_y[31:16] == DRAW_HEIGHT) begin
      cursor_y <= {DRAW_HEIGHT - 1, 16'b0};
    end else if (cursor_y[31:16] == 0) begin
      cursor_y <= {16'b1, 16'b0};
    end

  end

  enum {
    PRESSED,
    RELEASED
  } state = RELEASED;

  always_ff @(posedge clk) begin
    case (state)
      PRESSED: begin
        if (KEY[0] == 1) begin
          state <= RELEASED;
        end
      end
      RELEASED: begin
        if (KEY[0] == 0) begin
          state <= PRESSED;
          cursor_field_x_prev <= cursor_field_x;
          cursor_field_y_prev <= cursor_field_y;
        end
      end
    endcase
  end

endmodule



