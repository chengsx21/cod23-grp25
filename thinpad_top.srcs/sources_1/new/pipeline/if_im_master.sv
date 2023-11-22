module if_im_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire pc_sel_i,
    output logic [DATA_WIDTH-1:0] inst_o,
    output logic im_ready_o,

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
    logic im_state;

    logic [ADDR_WIDTH-1:0] pc_reg;
    logic [DATA_WIDTH-1:0] inst_reg;
    logic branch_reg;

    logic im_fetch_ready;
    logic im_fetch_identical;

    // Whether the Branch is after a Complete Fetch
    assign im_fetch_identical = (pc_i == pc_reg);
    assign im_fetch_ready = (wb_ack_i || wb_ack_reg) && im_fetch_identical;
    assign im_ready_o = im_fetch_ready && (~pc_sel_i) && (~branch_reg);

    assign wb_cyc_o = wb_stb_o;
    assign wb_adr_o = pc_i;
    assign wb_dat_o = 32'h0000_0000;
    assign wb_sel_o = 4'b1111;
    assign wb_we_o = 1'b0;

    always_comb begin
        // Receive Ack from Slave
        if (wb_ack_i) begin
            inst_o = wb_dat_i;
        end
        else if (im_ready_o) begin
            inst_o = inst_reg;
        end
        else begin
            inst_o = 32'h0000_0000;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            im_state <= 1'b0;
            pc_reg <= 32'h0000_0000;
            inst_reg <= 32'h0000_0000;
            wb_ack_reg <= 1'b0;
            branch_reg <= 1'b0;
        end
        else begin
            // Branch While Fetching, Wait for Previous Ack
            if (pc_sel_i && (~im_fetch_ready)) begin
                branch_reg <= 1'b1;
            end

            case (im_state)
                1'b0: begin
                    //* State Init *//
                    if (~im_fetch_identical) begin
                        im_state <= 1'b1;
                        wb_stb_o <= 1'b1;
                        wb_ack_reg <= 1'b0;
                        pc_reg <= pc_i;
                    end
                end
                1'b1: begin
                    //* State Read *//
                    if (wb_ack_i) begin
                        im_state <= 1'b0;
                        wb_stb_o <= 1'b0;
                        if (branch_reg) begin
                            // Previous Ack, Wait for next Ack
                            branch_reg <= 1'b0;
                        end
                        else begin
                            wb_ack_reg <= 1'b1;
                            inst_reg <= wb_dat_i;
                        end
                    end
                end
            endcase
        end

    end

endmodule
