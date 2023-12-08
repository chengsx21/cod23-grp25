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

    logic wb_ack_reg;
    logic [1:0] dm_state;

    logic dm_en_reg;
    logic dm_we_reg;
    logic [2:0] dm_dat_width_reg;
    logic [ADDR_WIDTH-1:0] dm_adr_reg;
    logic [DATA_WIDTH-1:0] dm_dat_i_reg;
    logic [DATA_WIDTH-1:0] dm_dat_o_reg;

    logic dm_fetch_identical;
    logic dm_fetch_ready;

    //  Follow the Code in File `if_im_master.sv`
    assign dm_fetch_identical = (dm_en_i == dm_en_reg) && (dm_we_i == dm_we_reg) && (dm_dat_width_i == dm_dat_width_reg) && (dm_adr_i == dm_adr_reg) && (dm_dat_i == dm_dat_i_reg);
    assign dm_fetch_ready = (wb_ack_i || wb_ack_reg) && dm_fetch_identical;
    assign dm_ready_o = (~dm_en_i) || dm_fetch_ready;

    // Follow the Code in File `lab5_master.sv`
    logic [DATA_WIDTH-1:0] wb_dat_s;
    assign wb_dat_s = (wb_dat_i >> ((dm_adr_reg & 2'b11) << 2'b11));

    always_comb begin
        // Receive Ack from Slave
        if (wb_ack_i) begin
            case (dm_dat_width_reg)
                3'b001: begin
                    dm_dat_o = {{24{wb_dat_s[7]}}, wb_dat_s[7:0]};
                end
                default: begin
                    dm_dat_o = wb_dat_s;
                end
            endcase
        end
        else if (dm_ready_o) begin
            dm_dat_o = dm_dat_o_reg;
        end
        else begin
            dm_dat_o = 32'h0000_0000;
        end
    end

    assign wb_cyc_o = wb_stb_o;

    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            dm_state <= 2'b00;
            wb_ack_reg <= 1'b0;
            dm_en_reg <= 1'b0;
            dm_we_reg <= 1'b0;
            dm_dat_width_reg <= 3'b000;
            dm_adr_reg <= 32'h0000_0000;
            dm_dat_i_reg <= 32'h0000_0000;
            dm_dat_o_reg <= 32'h0000_0000;

            wb_stb_o <= 1'b0;
            wb_adr_o <= 32'h0000_0000;
            wb_dat_o <= 32'h0000_0000;
            wb_sel_o <= 4'h0;
            wb_we_o <= 1'b0;
        end
        else begin
            case (dm_state)
                2'b00: begin
                    //* State Init *//
                    if (dm_en_i) begin
                        wb_ack_reg <= 1'b0;
                        dm_en_reg <= dm_en_i;
                        dm_we_reg <= dm_we_i;
                        dm_dat_width_reg <= dm_dat_width_i;
                        dm_adr_reg <= dm_adr_i;
                        dm_dat_i_reg <= dm_dat_i;

                        // Go To State Write
                        if (dm_we_i) begin
                            dm_state <= 2'b10;
                            wb_stb_o <= 1'b1;
                            wb_adr_o <= dm_adr_i;
                            wb_dat_o <= dm_dat_i;
                            wb_we_o <= 1'b1;
                            case (dm_dat_width_i)
                                // Follow the Code in File `lab5_master.sv`
                                3'b001: begin
                                    wb_sel_o <= (4'b0001 << (dm_adr_i & 2'b11));
                                end
                                default: begin
                                    wb_sel_o <= 4'b1111;
                                end
                            endcase
                        end

                        // Go To State Read
                        else begin
                            dm_state <= 2'b01;
                            wb_stb_o <= 1'b1;
                            wb_adr_o <= dm_adr_i;
                            wb_we_o <= 1'b0;
                            wb_sel_o <= 4'b1111;
                        end
                    end
                end

                2'b01: begin
                    //* State Read *//
                    if (wb_ack_i) begin
                        dm_state <= 2'b00;
                        wb_ack_reg <= 1'b1;
                        wb_stb_o <= 1'b0;
                        dm_en_reg <= 1'b0;
                        dm_we_reg <= 1'b0;

                        case (dm_dat_width_reg)
                            3'b001: begin
                                dm_dat_o_reg <= {{24{wb_dat_s[7]}}, wb_dat_s[7:0]};
                            end
                            default: begin
                                dm_dat_o_reg <= wb_dat_s;
                            end
                        endcase
                    end
                end

                2'b10: begin
                    //* State Write *//
                    if (wb_ack_i) begin
                        dm_state <= 2'b00;
                        wb_ack_reg <= 1'b1;
                        wb_stb_o <= 1'b0;
                        dm_en_reg <= 1'b0;
                        dm_we_reg <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule
