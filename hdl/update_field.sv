module update_field #(
    parameter FIELD_WIDTH = 8,
    parameter FIELD_HEIGHT = 6,
    localparam FIELD_SIZE = FIELD_WIDTH * FIELD_HEIGHT,
    parameter FIELD_DATAW = 96,  // xn, yn, mag
    localparam FIELD_ADDRW = $clog2(FIELD_SIZE),
    parameter BLOCK_SIZE = 80,
    localparam H_VEL_WIDTH = FIELD_WIDTH - 1,
    localparam H_VEL_HEIGHT = FIELD_HEIGHT,
    localparam H_VEL_SIZE = H_VEL_WIDTH * H_VEL_HEIGHT,
    localparam V_VEL_WIDTH = FIELD_WIDTH,
    localparam V_VEL_HEIGHT = FIELD_HEIGHT - 1,
    localparam V_VEL_SIZE = V_VEL_WIDTH * V_VEL_HEIGHT,
    parameter VEL_DATAW = 33,  // vel, wall
    localparam H_VEL_ADDRW = $clog2(H_VEL_SIZE),
    localparam V_VEL_ADDRW = $clog2(V_VEL_SIZE)
) (
    input logic clk,
    input logic start,
    output logic done,
    output logic [FIELD_ADDRW-1:0] field_addr_write,
    output logic [FIELD_DATAW-1:0] field_data_in,
    output logic field_we
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
  logic [31:0] signed vel_update;
  always_comb begin
    case (n)
      2: vel_update = vel_total >> 1;
      3: vel_update = vel_total * 32'sh55555555;  // 1/3
      4: vel_update = vel_total >> 2;
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
      .VEL_DATAW(VEL_DATAW),
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




  enum {
    IDLE,
    READ2,
    SUB2,
    CHANGE_FIELD2,
    READ3,
    NORM3,
    CHANGE_FIELD3
  } state;

  always_ff @(posedge clk) begin

    done <= 0;
    field_we <= 0;

    case (state)
      READ2: begin
        start_read_vels <= 0;
        start_write_vels <= 0;
        if (done_read_vels) begin
          state <= SUB2;
          vel_total <= $signed(
              vx1[31:0]
          ) - $signed(
              vx2[31:0]
          ) + $signed(
              vy1[31:0]
          ) - $signed(
              vy2[31:0]
          );
        end
      end
      SUB2: begin
        start_write_vels <= 1;
        state <= CHANGE_FIELD2;
        vx1_write <= {vx1[32], $signed(vx1[31:0]) - vel_update};
        vx2_write <= {vx2[32], $signed(vx2[31:0]) + vel_update};
        vy1_write <= {vy1[32], $signed(vy1[31:0]) - vel_update};
        vy2_write <= {vy2[32], $signed(vy2[31:0]) + vel_update};
      end
      CHANGE_FIELD2: begin
        state <= READ2;
        start_read_vels <= 1;

        field_x <= field_x_next;
        field_y <= field_y_next;
        field_addr_write <= field_addr_write + 1;

        if (field_end_pos) begin
          state <= READ3;
          field_x <= 0;
          field_y <= 0;
          field_addr_write <= 0;
        end
      end
      READ3: begin
        start_read_vels <= 0;
        if (done_read_vels) begin
          state <= NORM;
          startnorm <= 1;
          xi <= $signed(vx1[31:0]) + $signed(vx2[31:0]);
          yi <= $signed(vy1[31:0]) + $signed(vy2[31:0]);
        end
      end
      NORM3: begin
        startnorm <= 0;
        if (donenorm) begin
          state <= CHANGE_FIELD;
          field_data_in <= {xn, yn, mag};
          field_we <= 1;
        end
      end
      CHANGE_FIELD3: begin
        state <= READ3;
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

          state <= READ2;
          start_read_vels <= 1;
        end
      end
    endcase
  end

endmodule
