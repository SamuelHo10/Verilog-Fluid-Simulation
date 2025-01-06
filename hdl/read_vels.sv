module read_vels #(
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
    parameter VEL_DATAW = 33,  // wall, vel 
    parameter H_VEL_ADDRW = $clog2(H_VEL_SIZE),
    parameter V_VEL_ADDRW = $clog2(V_VEL_SIZE)
) (
    input logic clk,
    input logic start,
    output logic [H_VEL_ADDRW-1:0] h_vel_addr_read,
    output logic [V_VEL_ADDRW-1:0] v_vel_addr_read,
    input logic [VEL_DATAW-1:0] h_vel_data_out,
    input logic [VEL_DATAW-1:0] v_vel_data_out,
    input logic [31:0] field_x,
    input logic [31:0] field_y,
    output logic [VEL_DATAW-1:0] vx1,
    output logic [VEL_DATAW-1:0] vx2,
    output logic [VEL_DATAW-1:0] vy1,
    output logic [VEL_DATAW-1:0] vy2,
    output logic [2:0] n,
    output logic done
);
  logic [VEL_DATAW-1:0] vx_read, vy_read;
  logic side;
  logic valid_x, valid_y;

  always_comb begin
    valid_x = 0;
    valid_y = 0;
    h_vel_addr_read = 0;
    v_vel_addr_read = 0;

    if (side) begin
      if (field_x != 0) begin
        valid_x = 1;
        h_vel_addr_read = (field_x - 1) + (field_y * H_VEL_WIDTH);
      end

      if (field_y != 0) begin
        valid_y = 1;
        v_vel_addr_read = (field_x) + ((field_y - 1) * V_VEL_WIDTH);
      end
    end else begin
      if (field_x != FIELD_WIDTH - 1) begin
        valid_x = 1;
        h_vel_addr_read = (field_x) + (field_y * H_VEL_WIDTH);
      end

      if (field_y != FIELD_HEIGHT - 1) begin
        valid_y = 1;
        v_vel_addr_read = (field_x) + (field_y * V_VEL_WIDTH);
      end
    end

    vx_read = valid_x && h_vel_data_out[32] ? h_vel_data_out : 0;

    vy_read = valid_y && v_vel_data_out[32] ? v_vel_data_out : 0;

    n = vx1[32] + vx2[32] + vy1[32] + vy2[32];

  end



  enum {
    IDLE,
    READ_VELS1,
    READ_VELS2
  } state;

  always_ff @(posedge clk) begin
    done <= 0;
    case (state)
      READ_VELS1: begin
        side  <= 0;
        vx1   <= vx_read;
        vy1   <= vy_read;
        state <= READ_VELS2;
      end
      READ_VELS2: begin
        vx2   <= vx_read;
        vy2   <= vy_read;
        state <= IDLE;
        done  <= 1;
      end
      default: begin
        if (start) begin
          state <= READ_VELS1;
          side  <= 1;
        end
      end
    endcase
  end


endmodule
