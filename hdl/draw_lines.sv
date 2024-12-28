module draw_lines #(
    parameter line_width = 4
) (
    input  logic clk,
    input  logic start,
    output logic done
);
//   logic [31:0] xi, yi, xn, yn;
//   logic donenorm, startnorm;

//   norm norm_inst (
//       .x(xi),
//       .y(yi),
//       .clk(clk),
//       .start(startnorm),
//       .xn(),
//       .yn(divisor),
//       .done(done1)
//   );

  enum {
    IDLE,
    STEP1,  // calculate dot product
    STEP2   // calculate distance
  } state;

  always_ff @(posedge clk) begin
    done <= 0;
    case (state)
      STEP1: begin
        state <= STEP2;

        startnorm <= 1;
      end
      STEP2: begin
        startnorm <= 0;
        if (done1) begin
          state <= STEP3;
        end
      end
      STEP3: begin
        done  <= 1;
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
