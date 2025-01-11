module update_field #(
    parameter FIELD_WIDTH = 8,
    parameter FIELD_HEIGHT = 6,
    parameter FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT,
    parameter FIELD_DATAW = 96,  // xn, yn, mag
    parameter FIELD_ADDRW = $clog2(FIELD_SIZE),
    parameter BLOCK_SIZE = 80,
    parameter H_VEL_WIDTH = FIELD_WIDTH - 1,
    parameter H_VEL_HEIGHT = FIELD_HEIGHT,
    parameter H_VEL_SIZE = H_VEL_WIDTH * H_VEL_HEIGHT,
    parameter V_VEL_WIDTH = FIELD_WIDTH,
    parameter V_VEL_HEIGHT = FIELD_HEIGHT - 1,
    parameter V_VEL_SIZE = V_VEL_WIDTH * V_VEL_HEIGHT,
    parameter VEL_DATAW = 33,  // vel, wall
    parameter H_VEL_ADDRW = $clog2(H_VEL_SIZE),
    parameter V_VEL_ADDRW = $clog2(V_VEL_SIZE)
) (
    input logic clk,
    input logic start,
    input logic [15:0] cursor_field_x_prev,
    input logic [15:0] cursor_field_y_prev,
    input logic [15:0] cursor_field_x,
    input logic [15:0] cursor_field_y,
    input logic [31:0] cursor_x,
    input logic [31:0] cursor_y,
    input logic key_pressed,
    output logic done,
    output logic [FIELD_ADDRW-1:0] field_addr_write,
    output logic [FIELD_DATAW-1:0] field_data_in,
    output logic field_we,
    output logic [7:0] hex0,
    output logic [7:0] hex1,
    output logic [7:0] hex2,
    output logic [7:0] hex3,
    output logic [7:0] hex4,
    output logic [7:0] hex5
);

  logic [31:0] xi, yi, xn, yn, mag;
  logic donenorm, startnorm;

  norm norm_inst (
      .x(xi),
      .y(yi),
      .clk(clk),
      .start(startnorm),
      .xn(xn),
      .yn(yn),
      .mag(mag),
      .done(donenorm)
  );

  logic h_vel_we, v_vel_we;
  logic [H_VEL_ADDRW-1:0] h_vel_addr_write, h_vel_addr_read;
  logic [VEL_DATAW-1:0] h_vel_data_in, h_vel_data_out;
  logic [V_VEL_ADDRW-1:0] v_vel_addr_write, v_vel_addr_read;
  logic [VEL_DATAW-1:0] v_vel_data_in, v_vel_data_out;


  bram_sdp #(
      .WIDTH (VEL_DATAW),
      .DEPTH (H_VEL_SIZE),
      .INIT_F("h_vels.mem")
  ) bram_h_vel_inst (
      .clk_write(clk),
      .clk_read(clk),
      .we(h_vel_we),
      .addr_write(h_vel_addr_write),
      .addr_read(h_vel_addr_read),
      .data_in(h_vel_data_in),
      .data_out(h_vel_data_out)
  );

  bram_sdp #(
      .WIDTH (VEL_DATAW),
      .DEPTH (V_VEL_SIZE),
      .INIT_F("v_vels.mem")
  ) bram_v_vel_inst (
      .clk_write(clk),
      .clk_read(clk),
      .we(v_vel_we),
      .addr_write(v_vel_addr_write),
      .addr_read(v_vel_addr_read),
      .data_in(v_vel_data_in),
      .data_out(v_vel_data_out)
  );

  logic [31:0] field_x, field_y;
  logic [2:0] n;
  logic [VEL_DATAW-1:0] vx1, vx2, vy1, vy2;
  logic signed [31:0] vel_total;
  logic start_read_vels, done_read_vels;
  read_vels #(
      .FIELD_WIDTH(FIELD_WIDTH),
      .FIELD_HEIGHT(FIELD_HEIGHT),
      .FIELD_SIZE(FIELD_SIZE),
      .FIELD_DATAW(FIELD_DATAW),
      .FIELD_ADDRW(FIELD_ADDRW),
      .BLOCK_SIZE(BLOCK_SIZE),
      .H_VEL_WIDTH(H_VEL_WIDTH),
      .H_VEL_HEIGHT(H_VEL_HEIGHT),
      .H_VEL_SIZE(H_VEL_SIZE),
      .V_VEL_WIDTH(V_VEL_WIDTH),
      .V_VEL_HEIGHT(V_VEL_HEIGHT),
      .V_VEL_SIZE(V_VEL_SIZE),
      .VEL_DATAW(VEL_DATAW),
      .H_VEL_ADDRW(H_VEL_ADDRW),
      .V_VEL_ADDRW(V_VEL_ADDRW)
  ) read_vels_inst (
      .clk(clk),
      .start(start_read_vels),
      .h_vel_addr_read(h_vel_addr_read),
      .v_vel_addr_read(v_vel_addr_read),
      .h_vel_data_out(h_vel_data_out),
      .v_vel_data_out(v_vel_data_out),
      .field_x(field_x),
      .field_y(field_y),
      .vx1(vx1),
      .vx2(vx2),
      .vy1(vy1),
      .vy2(vy2),
      .n(n),
      .done(done_read_vels)
  );

  // field position incrementation logic
  logic [31:0] field_x_next, field_y_next;
  logic field_end_pos;
  always_comb begin
    field_x_next = field_x + 1;
    field_y_next = field_y;
    if (field_x == FIELD_WIDTH - 1) begin
      field_x_next = 0;
      field_y_next = field_y + 1;
    end
    field_end_pos = (field_x == FIELD_WIDTH - 1 && field_y == FIELD_HEIGHT - 1);
  end

  // update velocity logic
  logic signed [31:0] vel_update;
  logic signed [63:0] one_half_vel_total, one_third_vel_total, one_fourth_vel_total;
  always_comb begin
    one_third_vel_total  = vel_total * 32'sh5555;
    one_half_vel_total   = vel_total * 32'sh8000;
    one_fourth_vel_total = vel_total * 32'sh4000;
    case (n)
      2: vel_update = one_half_vel_total[47:16];
      3: vel_update = one_third_vel_total[47:16];
      4: vel_update = one_fourth_vel_total[47:16];
      default: vel_update = 0;
    endcase
  end

  logic [VEL_DATAW-1:0] vx1_write, vx2_write, vy1_write, vy2_write;
  logic start_write_vels, done_write_vels;

  write_vels #(
      .FIELD_WIDTH(FIELD_WIDTH),
      .FIELD_HEIGHT(FIELD_HEIGHT),
      .FIELD_DATAW(FIELD_DATAW),
      .BLOCK_SIZE(BLOCK_SIZE),
      .VEL_DATAW(VEL_DATAW)
  ) write_vels_inst (
      .clk(clk),
      .start(start_write_vels),
      .h_vel_addr_write(h_vel_addr_write),
      .v_vel_addr_write(v_vel_addr_write),
      .h_vel_data_in(h_vel_data_in),
      .v_vel_data_in(v_vel_data_in),
      .h_vel_we(h_vel_we),
      .v_vel_we(v_vel_we),
      .field_x(field_x),
      .field_y(field_y),
      .vx1(vx1_write),
      .vx2(vx2_write),
      .vy1(vy1_write),
      .vy2(vy2_write),
      .done(done_write_vels)
  );

  logic signed [31:0] field_cursor_diff_x, field_cursor_diff_y;
  logic [31:0] cursor_mag;
  always_comb begin
    field_cursor_diff_x = cursor_x - {cursor_field_x_prev * BLOCK_SIZE, 16'b0};
    field_cursor_diff_y = cursor_y - {cursor_field_y_prev * BLOCK_SIZE, 16'b0};
  end

  seg7 seg7_inst0 (
      .in(cursor_mag[3:0]),
      .display(hex0),
      .dot(1'b0)
  );

  seg7 seg7_inst1 (
      .in(cursor_mag[7:4]),
      .display(hex1),
      .dot(1'b0)
  );

  seg7 seg7_inst2 (
      .in(cursor_mag[11:8]),
      .display(hex2),
      .dot(1'b0)
  );

  seg7 seg7_inst3 (
      .in(cursor_mag[15:12]),
      .display(hex3),
      .dot(1'b0)
  );

  seg7 seg7_inst4 (
      .in(cursor_mag[19:16]),
      .display(hex4),
      .dot(1'b1)
  );

  seg7 seg7_inst5 (
      .in(cursor_mag[23:20]),
      .display(hex5),
      .dot(1'b0)
  );


  enum {
    IDLE,
    READ1,
    SUB1,
    CURSOR_FIELD,
    WRITE_VELS1,
    CHANGE_FIELD1,
    READ2,
    NORM2,
    CHANGE_FIELD2
  } state;

  always_ff @(posedge clk) begin

    done <= 0;
    field_we <= 0;
    start_read_vels <= 0;
    start_write_vels <= 0;
    startnorm <= 0;

    case (state)
      READ1: begin

        if (done_read_vels) begin
          state <= SUB1;
          vel_total <= $signed(
              vx1[31:0]
          ) - $signed(
              vx2[31:0]
          ) + $signed(
              vy1[31:0]
          ) - $signed(
              vy2[31:0]
          );
          if (key_pressed && cursor_field_x_prev == field_x && cursor_field_y_prev == field_y) begin
            state <= CURSOR_FIELD;
          end
        end
      end
      SUB1: begin
        start_write_vels <= 1;
        state <= WRITE_VELS1;
        vx1_write <= {vx1[32], $signed(vx1[31:0]) - vel_update};
        vx2_write <= {vx2[32], $signed(vx2[31:0]) + vel_update};
        vy1_write <= {vy1[32], $signed(vy1[31:0]) - vel_update};
        vy2_write <= {vy2[32], $signed(vy2[31:0]) + vel_update};
      end
      CURSOR_FIELD: begin
        start_write_vels <= 1;
        state <= WRITE_VELS1;
        vx1_write <= {vx1[32], field_cursor_diff_x >>> 3};
        vx2_write <= {vx2[32], field_cursor_diff_x >>> 3};
        vy1_write <= {vy1[32], field_cursor_diff_y >>> 3};
        vy2_write <= {vy2[32], field_cursor_diff_y >>> 3};
      end
      WRITE_VELS1: begin
        if (done_write_vels) begin
          state <= CHANGE_FIELD1;
        end
      end
      CHANGE_FIELD1: begin

        state <= READ1;
        start_read_vels <= 1;

        field_x <= field_x_next;
        field_y <= field_y_next;
        field_addr_write <= field_addr_write + 1;

        if (field_end_pos) begin
          state <= READ2;
          field_x <= 0;
          field_y <= 0;
          field_addr_write <= 0;
        end
      end
      READ2: begin
        if (done_read_vels) begin
          state <= NORM2;
          startnorm <= 1;
          xi <= $signed(vx1[31:0]) + $signed(vx2[31:0]);
          yi <= $signed(vy1[31:0]) + $signed(vy2[31:0]);
        end
      end
      NORM2: begin
        if (donenorm) begin
          state <= CHANGE_FIELD2;
          field_data_in <= {xn, yn, mag};

          if(field_x == cursor_field_x && field_y == cursor_field_y) begin
            cursor_mag <= mag;
          end

          field_we <= 1;
        end
      end
      CHANGE_FIELD2: begin
        state <= READ2;
        start_read_vels <= 1;

        field_x <= field_x_next;
        field_y <= field_y_next;
        field_addr_write <= field_addr_write + 1;

        if (field_end_pos) begin
          state <= IDLE;
          done <= 1;
          field_x <= 0;
          field_y <= 0;
          field_addr_write <= 0;

        end
      end
      default: begin
        if (start) begin
          field_x <= 0;
          field_y <= 0;
          field_addr_write <= 0;

          state <= READ1;
          start_read_vels <= 1;
        end
      end
    endcase
  end

endmodule
