module write_vels #(
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
    output logic [H_VEL_ADDRW-1:0] h_vel_addr_write,
    output logic [V_VEL_ADDRW-1:0] v_vel_addr_write,
    output logic [VEL_DATAW-1:0] h_vel_data_in,
    output logic [VEL_DATAW-1:0] v_vel_data_in,
    output logic h_vel_we,
    output logic v_vel_we,
    input logic [31:0] field_x,
    input logic [31:0] field_y,
    input logic [VEL_DATAW-1:0] vx1,
    input logic [VEL_DATAW-1:0] vx2,
    input logic [VEL_DATAW-1:0] vy1,
    input logic [VEL_DATAW-1:0] vy2,
    output logic done
);
  logic side;
  logic valid_x, valid_y;

  always_comb begin
    valid_x = 0;
    valid_y = 0;
    h_vel_addr_write = 0;
    v_vel_addr_write = 0;

    if (side) begin
      if (field_x != 0) begin
        valid_x = 1;
        h_vel_addr_write = (field_x - 1) + (field_y * H_VEL_WIDTH);
      end

      if (field_y != 0) begin
        valid_y = 1;
        v_vel_addr_write = (field_x) + ((field_y - 1) * V_VEL_WIDTH);
      end
    end else begin
      if (field_x != FIELD_WIDTH - 1) begin
        valid_x = 1;
        h_vel_addr_write = (field_x) + (field_y * H_VEL_WIDTH);
      end

      if (field_y != FIELD_HEIGHT - 1) begin
        valid_y = 1;
        v_vel_addr_write = (field_x) + (field_y * V_VEL_WIDTH);
      end
    end
  end



  enum {
    IDLE,
    SWITCH_SIDE,
    WRITE_VELS1,
    WRITE_VELS2
  } state;

  always_ff @(posedge clk) begin
    done <= 0;
    h_vel_we <= 0;
    v_vel_we <= 0;
    case (state)
      WRITE_VELS1: begin
        if (valid_x) begin
          h_vel_data_in <= vx1;
          h_vel_we <= 1;
        end
        if (valid_y) begin
          v_vel_data_in <= vy1;
          v_vel_we <= 1;
        end
        state <= SWITCH_SIDE;
      end
      SWITCH_SIDE: begin
        side <= 0;
        state <= WRITE_VELS2;
      end
      WRITE_VELS2: begin
        if (valid_x) begin
          h_vel_data_in <= vx2;
          h_vel_we <= 1;
        end
        if (valid_y) begin
          v_vel_data_in <= vy2;
          v_vel_we <= 1;
        end
        state <= IDLE;
        done  <= 1;
      end
      default: begin
        if (start) begin
          state <= WRITE_VELS1;
          side <= 1;
        end
      end
    endcase
  end


endmodule
