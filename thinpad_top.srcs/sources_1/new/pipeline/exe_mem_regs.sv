module exe_mem_regs #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,

    // [EXE] ~ [MEM]
    input wire [DATA_WIDTH-1:0] pc_i,
    output logic [DATA_WIDTH-1:0] pc_o,
    input wire [DATA_WIDTH-1:0] alu_y_i,
    output logic [DATA_WIDTH-1:0] alu_y_o,
    input wire [DATA_WIDTH-1:0] rs2_dat_i,
    output logic [DATA_WIDTH-1:0] rs2_dat_o,
    input wire dm_en_i,
    output logic dm_en_o,
    input wire dm_we_i,
    output logic dm_we_o,
    input wire [2:0] dm_dat_width_i,
    output logic [2:0] dm_dat_width_o,
    input wire [1:0] writeback_mux_sel_i,
    output logic [1:0] writeback_mux_sel_o,

    // [MEM] ~ [WRITEBACK]
    input wire [4:0] rd_i,
    output logic [4:0] rd_o,
    input wire reg_we_i,
    output logic reg_we_o,

    // [CSR]
    input wire csr_we_i,
    output logic csr_we_o,
    input wire [11:0] csr_waddr_i,
    output logic [11:0] csr_waddr_o,
    input wire [DATA_WIDTH-1:0] csr_wdata_i,
    output logic [DATA_WIDTH-1:0] csr_wdata_o,
    input wire [1:0] instruction_mode_i,
    output logic [1:0] instruction_mode_o
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_o <= 0;
            alu_y_o <= 0;
            rs2_dat_o <= 0;
            dm_en_o <= 0;
            dm_we_o <= 0;
            dm_dat_width_o <= 4;
            writeback_mux_sel_o <= 1; // ALU

            rd_o <= 0;
            reg_we_o <= 0;

            csr_we_o <= 0;
            csr_waddr_o <= 0;
            csr_wdata_o <= 0;
            instruction_mode_o <= 0;
        end else if (stall_i) begin
            // Do nothing
        end else if (bubble_i) begin
            pc_o <= 0;
            alu_y_o <= 0;
            rs2_dat_o <= 0;
            dm_en_o <= 0;
            dm_we_o <= 0;
            dm_dat_width_o <= 4;
            writeback_mux_sel_o <= 1; // ALU

            rd_o <= 0;
            reg_we_o <= 0;

            csr_we_o <= 0;
            csr_waddr_o <= 0;
            csr_wdata_o <= 0;
            instruction_mode_o <= 0;
        end else begin
            pc_o <= pc_i;
            alu_y_o <= alu_y_i;
            rs2_dat_o <= rs2_dat_i;
            dm_en_o <= dm_en_i;
            dm_we_o <= dm_we_i;
            dm_dat_width_o <= dm_dat_width_i;
            writeback_mux_sel_o <= writeback_mux_sel_i;

            rd_o <= rd_i;
            reg_we_o <= reg_we_i;

            csr_we_o <= csr_we_i;
            csr_waddr_o <= csr_waddr_i;
            csr_wdata_o <= csr_wdata_i;
            instruction_mode_o <= instruction_mode_i;
        end
    end
endmodule
