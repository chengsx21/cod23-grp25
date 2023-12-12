module if_im_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire pc_sel_i,
    input wire pc_exception_i,
    input wire cache_en_i,
    output logic [DATA_WIDTH-1:0] inst_o,
    output logic im_ready_o,
    output logic cache_we_o,

    // paging
    input wire [1:0] privilidge_i,
    input wire paging_en_i,
    input wire mmu_ready_i,
    input wire [ADDR_WIDTH-1:0] phy_addr_i,
    input wire page_fault_en_i,
    output logic mmu_next_fetch_o,

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

    typedef enum logic [3:0] {
        READ_1,
        READ_1_MISS
    } im_state_t;

    im_state_t im_cstate;
    im_state_t im_nstate;

    reg no_int_reg;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            im_cstate <= READ_1;
            no_int_reg <= 1'b0;
        end
        else begin
            im_cstate <= im_nstate;
            if (no_int_reg) begin
                if (wb_ack_i) begin
                    no_int_reg <= 1'b0;
                end
            end
            else begin
                if (~cache_en_i) begin
                    no_int_reg <= 1'b1;
                end
            end
        end
    end

    always_comb begin
        im_nstate = READ_1;
        case (im_cstate)
            READ_1: begin
                if (cache_en_i) begin
                    im_nstate = READ_1;
                end
                else begin
                    if (~wb_ack_i && ~(pc_sel_i || pc_exception_i)) begin
                        im_nstate = READ_1;
                    end
                    else if (~wb_ack_i && (pc_sel_i || pc_exception_i)) begin
                        im_nstate = READ_1_MISS;
                    end
                    else if (wb_ack_i && ~(pc_sel_i || pc_exception_i)) begin
                        im_nstate = READ_1;
                    end
                    else begin
                        im_nstate = READ_1;
                    end
                end
            end
            READ_1_MISS: begin
                if (wb_ack_i) begin
                    im_nstate = READ_1;
                end
                else begin
                    im_nstate = READ_1_MISS;
                end
            end
            default: begin
                im_nstate = READ_1;
            end
        endcase
    end

    always_comb begin
        if (privilidge_i == 2'b11 || ~paging_en_i) begin
            wb_dat_o = {DATA_WIDTH{1'b0}};
            wb_sel_o = 4'b1111;
            wb_we_o = 1'b0;
            wb_cyc_o = ~wb_ack_i && (no_int_reg ? 1'b1 : ~cache_en_i);
            wb_stb_o = ~wb_ack_i && (no_int_reg ? 1'b1 : ~cache_en_i);
            wb_adr_o = pc_i;
            inst_o = (wb_ack_i && im_cstate != READ_1_MISS) ? wb_dat_i : {DATA_WIDTH{1'b0}};
            im_ready_o = (cache_en_i && ~no_int_reg) || (~cache_en_i && wb_ack_i && im_cstate != READ_1_MISS);
            cache_we_o = ~cache_en_i && wb_ack_i && im_cstate != READ_1_MISS;
            mmu_next_fetch_o = 1'b1;
        end
        else if (page_fault_en_i) begin
            wb_dat_o = {DATA_WIDTH{1'b0}};
            wb_sel_o = 4'b1111;
            wb_we_o = 1'b0;
            wb_cyc_o = 1'b0;
            wb_stb_o = 1'b0;
            wb_adr_o = {ADDR_WIDTH{1'b0}};
            inst_o = 32'h0000_0013;
            im_ready_o = 1'b1;
            cache_we_o = 1'b0;
            mmu_next_fetch_o = 1'b1;
        end
        else begin
            wb_dat_o = {DATA_WIDTH{1'b0}};
            wb_sel_o = 4'b1111;
            wb_we_o = 1'b0;
            wb_cyc_o = ~wb_ack_i && (no_int_reg ? 1'b1 : ~cache_en_i) && mmu_ready_i;
            wb_stb_o = ~wb_ack_i && (no_int_reg ? 1'b1 : ~cache_en_i) && mmu_ready_i;
            wb_adr_o = phy_addr_i;
            inst_o = (wb_ack_i && im_cstate != READ_1_MISS && mmu_ready_i) ? wb_dat_i : {DATA_WIDTH{1'b0}};
            im_ready_o = (cache_en_i && ~no_int_reg && mmu_ready_i) || (~cache_en_i && wb_ack_i && im_cstate != READ_1_MISS && mmu_ready_i);
            cache_we_o = ~cache_en_i && wb_ack_i && im_cstate != READ_1_MISS && mmu_ready_i;
            mmu_next_fetch_o = (cache_en_i && ~no_int_reg && mmu_ready_i) || (~cache_en_i && wb_ack_i && mmu_ready_i);
        end
    end

endmodule
