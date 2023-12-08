module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
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

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [SRAM_BYTES-1:0] sram_be_n
);

  // TODO: 实现 SRAM 控制器

  // 状态列表
  typedef enum logic [2:0] {
    STATE_IDLE = 0,
    STATE_READ = 1,
    STATE_READ_2 = 2,
    STATE_WRITE = 3,
    STATE_WRITE_2 = 4,
    STATE_WRITE_3 = 5,
    STATE_DONE = 6
  } state_t;

  // 现态与次态
  state_t state, n_state;  

  reg  sram_data_t; // 0 for in, 1 for out(write).
  wire [SRAM_DATA_WIDTH-1:0] sram_data_i;
  reg  [SRAM_DATA_WIDTH-1:0] sram_data_o;

  assign sram_data = sram_data_t? 32'bz: sram_data_o;
  assign sram_data_i = sram_data;

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
        n_state = STATE_WRITE_3;
      end
      STATE_WRITE_3: begin
        n_state = STATE_IDLE;
      end
      STATE_READ_2: begin
        n_state = STATE_IDLE;
      end
      default: begin
        n_state = STATE_DONE;
      end
    endcase
  end

  always_comb begin

    sram_addr = wb_adr_i >> 2'b10;
    sram_data_t = ~ (wb_stb_i & wb_we_i);
    sram_data_o = wb_dat_i;
    
    sram_ce_n = ~ wb_cyc_i;
    sram_oe_n = ~ (wb_cyc_i & (~wb_we_i));
    //sram_we_n = ~ (wb_cyc_i & wb_we_i);
    sram_be_n = ~ wb_sel_i;

    wb_ack_o = ((state == STATE_WRITE_3)|(state == STATE_READ_2));
    wb_dat_o = sram_data;
  end

  always_ff @( posedge clk_i ) begin 
    if (rst_i) begin
      sram_we_n <= 1'b1;
    end
    else begin
      case (n_state)
        STATE_IDLE: begin

        end
        STATE_WRITE_2: begin
          sram_we_n <= 1'b0;
        end
        STATE_WRITE_3: begin
          sram_we_n <= 1'b1;
        end
        STATE_READ_2: begin

        end
        
        default: begin

        end
      endcase
    end
  end

endmodule