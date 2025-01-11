
module seg7 (
    input  logic [3:0] in,
    output logic [7:0] display,
    input logic dot
);

  always_comb begin
    display[7] = ~dot;
    case (in)
      4'h0: display[6:0] = 7'b1000000;
      4'h1: display[6:0] = 7'b1111001;
      4'h2: display[6:0] = 7'b0100100;
      4'h3: display[6:0] = 7'b0110000;
      4'h4: display[6:0] = 7'b0011001;
      4'h5: display[6:0] = 7'b0010010;
      4'h6: display[6:0] = 7'b0000010;
      4'h7: display[6:0] = 7'b1111000;
      4'h8: display[6:0] = 7'b0000000;
      4'h9: display[6:0] = 7'b0010000;
      4'hA: display[6:0] = 7'b0001000;
      4'hB: display[6:0] = 7'b0000011;
      4'hC: display[6:0] = 7'b0100111;
      4'hD: display[6:0] = 7'b0100001;
      4'hE: display[6:0] = 7'b0000110;
      default: display[6:0] = 8'b10001110;  // 4'hF
    endcase

  end
endmodule