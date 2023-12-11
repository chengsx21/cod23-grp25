module mem_dm_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire dm_en_i,
    input wire dm_we_i,
    input wire [2:0] dm_dat_width_i,
    input wire [ADDR_WIDTH-1:0] dm_adr_i,
    input wire [DATA_WIDTH-1:0] dm_dat_i,
    output logic [DATA_WIDTH-1:0] dm_dat_o,
    output logic dm_ready_o,

    // Mtimer Interface Signals
    input wire [2*DATA_WIDTH-1:0] mt_mtime_i,
    input wire [2*DATA_WIDTH-1:0] mt_mtimecmp_i,
    output logic mt_mtime_we_o,
    output logic mt_mtimecmp_we_o,
    output logic mt_high_we_o,
    output logic [DATA_WIDTH-1:0] mt_mtime_wdata_o,

    // Wishbone Interface Signals
    output logic wb_cyc_o,
    output logic wb_stb_o,
    input wire wb_ack_i,
    output logic [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output logic [DATA_WIDTH/8-1:0] wb_sel_o,
    output logic wb_we_o
    );

    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE
    } dm_state_t;

    dm_state_t dm_state;

    logic clock_ack;
    logic is_clock_adr;
    logic [DATA_WIDTH-1:0] mt_mtime_rdata;
    logic [DATA_WIDTH-1:0] wb_dat_s;

    always_comb begin
        is_clock_adr = (dm_adr_i == 32'h0200bff8 || dm_adr_i == 32'h0200bffc || dm_adr_i == 32'h02004000 || dm_adr_i == 32'h02004004);
        clock_ack = dm_en_i && is_clock_adr;
        wb_dat_s = (wb_dat_i >> ((dm_adr_i & 2'b11) << 2'b11));
        wb_stb_o = dm_en_i && (~wb_ack_i) && (~clock_ack);
        wb_cyc_o = wb_stb_o;
        wb_adr_o = dm_adr_i;
        wb_dat_o = dm_dat_i;
        wb_we_o = dm_we_i;
        wb_sel_o = (dm_we_i && dm_dat_width_i == 3'b001) ? (4'b0001 << (dm_adr_i & 2'b11)) : 4'b1111;
        dm_ready_o = (~dm_en_i) || wb_ack_i || clock_ack;

        // Receive Ack from Slave
        if (wb_ack_i) begin
            case (dm_dat_width_i)
                3'b001: begin
                    dm_dat_o = {{24{wb_dat_s[7]}}, wb_dat_s[7:0]};
                end
                default: begin
                    dm_dat_o = wb_dat_s;
                end
            endcase
        end 
        else if (clock_ack) begin
            dm_dat_o = mt_mtime_rdata;
        end
        else begin
            dm_dat_o = 32'h0000_0000;
        end
    end

    always_comb begin
        // Mtimer Interface Signals
        mt_mtime_we_o = 1'b0;
        mt_mtimecmp_we_o = 1'b0;
        mt_high_we_o = 1'b0;
        mt_mtime_wdata_o = dm_dat_i;
        mt_mtime_rdata = 32'h0000_0000;

        if (dm_we_i) begin
            case (dm_adr_i)
                32'h0200bff8: begin
                    mt_mtime_we_o = 1'b1;
                    mt_high_we_o = 1'b0;
                end
                32'h0200bffc: begin
                    mt_mtime_we_o = 1'b1;
                    mt_high_we_o = 1'b1;
                end
                32'h02004000: begin
                    mt_mtimecmp_we_o = 1'b1;
                    mt_high_we_o = 1'b0;
                end
                32'h02004004: begin
                    mt_mtimecmp_we_o = 1'b1;
                    mt_high_we_o = 1'b1;
                end
            endcase
        end

        else begin
            case (dm_adr_i)
                32'h0200bff8: begin
                    mt_mtime_rdata = mt_mtime_i[DATA_WIDTH-1:0];
                end
                32'h0200bffc: begin
                    mt_mtime_rdata = mt_mtime_i[2*DATA_WIDTH-1:DATA_WIDTH];
                end
                32'h02004000: begin
                    mt_mtime_rdata = mt_mtimecmp_i[DATA_WIDTH-1:0];
                end
                32'h02004004: begin
                    mt_mtime_rdata = mt_mtimecmp_i[2*DATA_WIDTH-1:DATA_WIDTH];
                end
            endcase
        end
    end

    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            dm_state <= IDLE;
        end
        else begin
            case (dm_state)
                IDLE: begin
                    if (dm_en_i && (~is_clock_adr)) begin
                        if (dm_we_i) begin
                            dm_state <= WRITE;
                        end
                        else begin
                            dm_state <= READ;
                        end
                    end
                end

                READ: begin
                    if (wb_ack_i) begin
                        dm_state <= IDLE;
                    end
                end

                WRITE: begin
                    if (wb_ack_i) begin
                        dm_state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
