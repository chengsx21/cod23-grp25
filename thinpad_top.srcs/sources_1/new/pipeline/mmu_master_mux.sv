module mmu_master_mux #(
    parameter ADDR_WIDTH = 32
) (
    input wire sel_i,

    input wire mmu_wb_cyc_i,
    input wire mmu_wb_stb_i,
    output logic mmu_wb_ack_o,
    input wire [ADDR_WIDTH-1:0] mmu_wb_adr_i,
    input wire [DATA_WIDTH-1:0] mmu_wb_dat_i,
    output logic [DATA_WIDTH-1:0] mmu_wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] mmu_wb_sel_i,
    input wire mmu_wb_we_i,

    input wire master_wb_cyc_i,
    input wire master_wb_stb_i,
    output logic master_wb_ack_o,
    input wire [ADDR_WIDTH-1:0] master_wb_adr_i,
    input wire [DATA_WIDTH-1:0] master_wb_dat_i,
    output logic [DATA_WIDTH-1:0] master_wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] master_wb_sel_i,
    input wire master_wb_we_i,

    output logic wb_cyc_o,
    output logic wb_stb_o,
    input wire wb_ack_i,
    output logic [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output logic [DATA_WIDTH/8-1:0] wb_sel_o,
    output logic wb_we_o
);

    assign mmu_wb_ack_o = sel_i ? wb_ack_i : 1'b0;
    assign mmu_wb_dat_o = sel_i ? wb_dat_i : {DATA_WIDTH{1'b0}};

    assign master_wb_ack_o = sel_i ? 1'b0 : wb_ack_i;
    assign master_wb_dat_o = sel_i ? {DATA_WIDTH{1'b0}} : wb_dat_i;

    assign wb_cyc_o = sel_i ? mmu_wb_cyc_i : master_wb_cyc_i;
    assign wb_stb_o = sel_i ? mmu_wb_stb_i : master_wb_stb_i;
    assign wb_adr_o = sel_i ? mmu_wb_adr_i : master_wb_adr_i;
    assign wb_dat_o = sel_i ? mmu_wb_dat_i : master_wb_dat_i;
    assign wb_sel_o = sel_i ? mmu_wb_sel_i : master_wb_sel_i;
    assign wb_we_o = sel_i ? mmu_wb_we_i : master_wb_we_i;

endmodule
