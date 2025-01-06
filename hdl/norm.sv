

module norm (
    input logic signed [31:0] x,
    input logic signed [31:0] y,
    input logic clk,
    input logic start,
    output logic signed [31:0] xn,
    output logic signed [31:0] yn,
    output logic [31:0] mag,
    output logic done
);

  logic start1, start2, started2, done1;
  logic [63:0] magsqr;

  logic [31:0] divident, divisor, quotient;
  logic [31:0] radicand, root;
  logic donediv, donesqrt;
  logic startdiv, startsqrt;

  assign magsqr = x * x + y * y;

  div div_inst (
    .clk(clk),
    .start(startdiv),
    .n(divident),
    .d(divisor),
    .q(quotient),
    .done(donediv)
  );

  sqrt sqrt_inst (
    .clk(clk),
    .start(startsqrt),
    .rad(radicand),
    .root(root),
    .done(donesqrt)
  );


  enum {
    IDLE,
    STEP1, // calculate magnitude
    STEP2, // calculate root
    STEP3, // calculate x
    STEP4 // calculate y
  } state;

  always_ff @(posedge clk) begin
    done  <= 0;
    case (state)
      STEP1: begin
        state <= STEP2;
        radicand <= magsqr[47:16];
        startsqrt <= 1;
      end
      STEP2: begin
        startsqrt <= 0;
        if (donesqrt) begin
          state <= STEP3;
          mag <= root;
          divisor <= root;
          divident <= x;
          startdiv <= 1;
        end
      end
      STEP3: begin
        startdiv <= 0;
        if (donediv) begin
          xn <= quotient;
          state <= STEP4;
          divisor <= root;
          divident <= y;
          startdiv <= 1;
        end
      end
      STEP4: begin
        startdiv <= 0;
        if (donediv) begin
          state <= IDLE;
          yn <= quotient;
          done <= 1;
        end
      end
      default: begin
        if (start) begin
          state <= STEP1;
        end
      end
    endcase
  end

endmodule

