module pixel_on_line #(
    parameter LINE_WIDTH_SQR = 25
) (
    input logic signed [31:0] x,
    input logic signed [31:0] y,
    input logic signed [31:0] x0,
    input logic signed [31:0] y0,
    input logic signed [31:0] xn,
    input logic signed [31:0] yn,
    input logic signed [31:0] mag,
    output logic on_line
);

  logic signed [63:0] dot, x2, y2, dist_sqr;
  logic signed [31:0] dx, dy;
  logic signed [31:0] line_width_sqr = {LINE_WIDTH_SQR, 16'b0};


  always_comb begin
    dx = x - x0;
    dy = y - y0;
    dot = dx * xn + dy * yn;
    x2 = {x0, 16'b0} + xn * dot[47:16];
    y2 = {y0, 16'b0} + yn * dot[47:16];
    dist_sqr = (x - x2[47:16]) * (x - x2[47:16]) + (y - y2[47:16]) * (y - y2[47:16]);
    on_line = (dot[47:16] <= mag) && (dist_sqr[47:16] <= line_width_sqr);
  end

endmodule
