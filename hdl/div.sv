
// Two's complement divider
module div #(
    parameter WIDTH = 32,
    parameter FBITS = 16
) (
    input logic [WIDTH-1:0] n,  // Numerator
    input logic [WIDTH-1:0] d,  // Denominator
    input logic start,
    input logic clk,
    output logic [WIDTH-1:0] q,  // Quotient
    output logic [WIDTH-1:0] r,  // Remainder
    output logic done
);

  logic sign;
  logic [WIDTH-2:0] nu, du, qu, ru;  // unsigned

  assign sign = n[WIDTH-1] ^ d[WIDTH-1];

  // convert to unsigned
  assign nu   = n[WIDTH-1] ? ~(n[WIDTH-2:0] - 1) : n[WIDTH-2:0];
  assign du   = d[WIDTH-1] ? ~(d[WIDTH-2:0] - 1) : d[WIDTH-2:0];

  divu #(
      .WIDTH(WIDTH - 1),
      .FBITS(FBITS)
  ) divu_inst (
      nu,
      du,
      start,
      clk,
      qu,
      ru,
      done
  );

  assign q = sign ? {1'b1, ~qu + 1} : {1'b0, qu};
  assign r = {1'b0, ru};

endmodule

// Non-restoring divider
module divu #(
    parameter WIDTH = 31,
    parameter FBITS = 16
) (
    input logic [WIDTH-1:0] n,  // Numerator
    input logic [WIDTH-1:0] d,  // Denominator
    input logic start,
    input logic clk,
    output logic [WIDTH-1:0] q,  // Quotient
    output logic [WIDTH-1:0] r,  // Remainder
    output logic done
);
  localparam AQ_START = WIDTH * 2 + FBITS - 1;
  logic [$clog2(WIDTH) + 1:0] counter;
  logic [AQ_START:0] aq, aq_next;

  always_comb begin
    if (aq[AQ_START] == 1) begin
      aq_next = aq << 1;
      aq_next[AQ_START:WIDTH] = aq_next[AQ_START:WIDTH] + d;
    end else begin
      aq_next = aq << 1;
      aq_next[AQ_START:WIDTH] = aq_next[AQ_START:WIDTH] - d;
    end

    if (aq_next[AQ_START]) begin
      aq_next[0] = 1'b0;
    end else begin
      aq_next[0] = 1'b1;
    end
  end

  enum {
    IDLE,
    CALC
  } state;

  always_ff @(posedge clk) begin
    case (state)
      CALC: begin
        counter <= counter - 1;
        aq <= aq_next;
        if (counter == 1) begin
          done  <= 1;
          state <= IDLE;
        end
      end
      default: begin
        done <= 0;
        if (start) begin
          counter <= WIDTH + FBITS;
          aq <= 0;
          aq[WIDTH-1:0] <= n;
          state <= CALC;
        end
      end
    endcase
  end

  assign r = aq[AQ_START] ? aq[WIDTH*2-1:WIDTH] + d : aq[WIDTH*2-1:WIDTH];
  assign q = aq[WIDTH-1:0];


endmodule
