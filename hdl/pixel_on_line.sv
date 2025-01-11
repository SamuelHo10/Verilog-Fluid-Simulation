module pixel_on_line #(
    parameter LINE_WIDTH_SQR = 25,
    parameter LINE_WIDTH = 5
) (
    input logic signed [31:0] x,
    input logic signed [31:0] y,
    input logic signed [31:0] x0,
    input logic signed [31:0] y0,
    input logic signed [31:0] xn,
    input logic signed [31:0] yn,
    input logic signed [31:0] mag,
    input logic start,
    input logic clk,
    output logic on_line,
    output logic we
);

  logic signed [63:0] dot, x2, y2, dist_sqr, dx2, dy2, mag_dot_sqr;
  logic signed [31:0] dx, dy;
  logic signed [31:0] line_width_sqr = {LINE_WIDTH_SQR, 16'b0};
  logic signed [31:0] line_width = {LINE_WIDTH, 16'b0};


  assign dx = x - x0;
  assign dy = y - y0;

  assign dx2 = $signed(x - $signed(x2[47:16]));
  assign dy2 = $signed(y - $signed(y2[47:16]));

  assign mag_dot_sqr = $signed(dot[47:16]) * $signed(dot[47:16]) + mag * mag - $signed(dot[47:16]) * $signed(mag << 1);

  //  verilog_format: off
  always_comb begin
    on_line = 0;
    if ($signed( dot[47:16]) >= 0 && $signed(dot[47:16]) <= mag) begin
      if ($signed(dist_sqr[47:16]) <= line_width_sqr && $signed(dot[47:16]) <= mag - line_width) begin
        on_line = 1;
      end else if ($signed( dot[47:16]) > mag - line_width && $signed(dist_sqr[47:16]) <= $signed(mag_dot_sqr[47:16])) begin
        on_line = 1;
      end
    end
  end 
  //  verilog_format: on

  enum {
    IDLE,
    STEP1,
    STEP2,
    STEP3
  } state;

  always_ff @(posedge clk) begin
    we <= 0;
    case (state)
      STEP1: begin
        dot   <= dx * xn + dy * yn;
        state <= STEP2;
      end
      STEP2: begin
        x2 <= $signed({x0, 16'b0}) + xn * $signed(dot[47:16]);
        y2 <= $signed({y0, 16'b0}) + yn * $signed(dot[47:16]);
        state <= STEP3;
      end
      STEP3: begin
        dist_sqr <= dx2 * dx2 + dy2 * dy2;
        we <= 1;
        state <= IDLE;
      end
      default: begin
        if (start) begin
          state <= STEP1;
        end
      end

    endcase
  end

endmodule
