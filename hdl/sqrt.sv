
//square root algorithm from https://projectf.io/posts/square-root-in-verilog/
module sqrt #(
    parameter WIDTH = 32,  // width of radicand
    parameter FBITS = 16   // fractional bits (for fixed point)
) (
    input  wire logic             clk,
    input  wire logic             start,  // start signal
    output logic                  done,   // calculation in progress
    input  wire logic [WIDTH-1:0] rad,    // radicand
    output logic      [WIDTH-1:0] root,   // root
    output logic      [WIDTH-1:0] rem     // remainder
);

  logic [WIDTH-1:0] x, x_next;  // radicand copy
  logic [WIDTH-1:0] q, q_next;  // intermediate root (quotient)
  logic [WIDTH+1:0] ac, ac_next;  // accumulator (2 bits wider)
  logic [WIDTH+1:0] test_res;  // sign test result (2 bits wider)

  localparam ITER = (WIDTH + FBITS) >> 1;  // iterations are half radicand+fbits width
  logic [$clog2(ITER)-1:0] i;  // iteration counter

  always_comb begin
    test_res = ac - {q, 2'b01};
    if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
      {ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
      q_next = {q[WIDTH-2:0], 1'b1};
    end else begin
      {ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
      q_next = q << 1;
    end
  end

  enum {
    IDLE,
    CALC
  } state;

  always_ff @(posedge clk) begin

    case (state)
      CALC: begin
        if (i == ITER - 1) begin
          done  <= 1;
          root  <= q_next;
          rem   <= ac_next[WIDTH+1:2];
          state <= IDLE;
        end else begin
          i  <= i + 1;
          x  <= x_next;
          ac <= ac_next;
          q  <= q_next;
        end
      end
      default: begin
        done <= 0;
        if (start) begin
          i <= 0;
          q <= 0;
          {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
          state <= CALC;
        end
      end
    endcase

  end
endmodule
