module bram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter BRAM_ADDR_WIDTH = 19,
    parameter BRAM_DATA_WIDTH = 8,

    localparam BRAM_BYTES = BRAM_DATA_WIDTH / 8
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // bram interface
    output reg [BRAM_ADDR_WIDTH-1:0] bram_addr,
    output reg [BRAM_DATA_WIDTH-1:0] bram_data_in,
    input wire [BRAM_DATA_WIDTH-1:0] bram_data_out,
    output reg bram_en,
    output reg bram_we
);

  // TODO: 实现 bram 控制器

  // 状态列表
  typedef enum logic [2:0] {
    STATE_IDLE = 0,
    STATE_READ_2 = 1,
    STATE_WRITE_2 = 2
  } state_t;

  // 现态与次态
  state_t state, n_state;  

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state <= STATE_IDLE;
    end
    else begin
      state <= n_state;
    end
  end

  always_comb begin
    case (state)
      STATE_IDLE: begin
        if (wb_stb_i & wb_cyc_i) begin
          if (wb_we_i) begin
            n_state = STATE_WRITE_2;
          end
          else begin
            n_state = STATE_READ_2;
          end
        end
        else begin
          n_state = STATE_IDLE;
        end
      end 
      STATE_WRITE_2: begin
        n_state = STATE_IDLE;
      end
      STATE_READ_2: begin
        n_state = STATE_IDLE;
      end
      default: begin
        n_state = STATE_IDLE;
      end
    endcase
  end

  always_comb begin

    bram_addr = wb_adr_i;
    bram_data_in = wb_dat_i[BRAM_DATA_WIDTH-1:0];
    
    bram_en = wb_cyc_i;
    bram_we = wb_we_i;

    wb_ack_o = ((state == STATE_WRITE_2)|(state == STATE_READ_2));
    wb_dat_o = {24'b0, bram_data_out};
  end

endmodule