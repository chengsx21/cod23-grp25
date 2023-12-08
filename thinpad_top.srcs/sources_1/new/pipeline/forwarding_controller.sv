module forwarding_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [4:0] id_rs1_i,
    input wire [4:0] id_rs2_i,
    input wire [4:0] exe_rd_i,
    input wire [4:0] mem_rd_i,
    input wire [4:0] writeback_rd_i,

    input wire exe_reg_we_i,
    input wire mem_reg_we_i,
    input wire writeback_reg_we_i,

    input wire [DATA_WIDTH-1:0] exe_data_i,
    input wire [DATA_WIDTH-1:0] mem_data_i,
    input wire [DATA_WIDTH-1:0] writeback_data_i,

    input wire [1:0] exe_writeback_mux_sel_i,

    output logic [DATA_WIDTH-1:0] rs1_dat_o,
    output logic [DATA_WIDTH-1:0] rs2_dat_o,
    output logic rs1_dat_sel_o,
    output logic rs2_dat_sel_o
    );

    //* rs1_forward *//
    always_comb begin
        if (id_rs1_i == 5'b0) begin
            rs1_dat_o = {DATA_WIDTH{1'b0}};
            rs1_dat_sel_o = 1'b0;
        end
        else if (exe_reg_we_i && exe_rd_i == id_rs1_i && exe_writeback_mux_sel_i != 2'b00) begin
            rs1_dat_o = exe_data_i;
            rs1_dat_sel_o = 1'b1;
        end
        else if (mem_reg_we_i && mem_rd_i == id_rs1_i) begin
            rs1_dat_o = mem_data_i;
            rs1_dat_sel_o = 1'b1;
        end
        else if (writeback_reg_we_i && writeback_rd_i == id_rs1_i) begin
            rs1_dat_o = writeback_data_i;
            rs1_dat_sel_o = 1'b1;
        end
        else begin
            rs1_dat_o = {DATA_WIDTH{1'b0}};
            rs1_dat_sel_o = 1'b0;
        end
    end

    //* rs2_forward *//
    always_comb begin
        if (id_rs2_i == 5'b0) begin
            rs2_dat_o = {DATA_WIDTH{1'b0}};
            rs2_dat_sel_o = 1'b0;
        end
        else if (exe_reg_we_i && exe_rd_i == id_rs2_i && exe_writeback_mux_sel_i != 2'b00) begin
            rs2_dat_o = exe_data_i;
            rs2_dat_sel_o = 1'b1;
        end
        else if (mem_reg_we_i && mem_rd_i == id_rs2_i) begin
            rs2_dat_o = mem_data_i;
            rs2_dat_sel_o = 1'b1;
        end
        else if (writeback_reg_we_i && writeback_rd_i == id_rs2_i) begin
            rs2_dat_o = writeback_data_i;
            rs2_dat_sel_o = 1'b1;
        end
        else begin
            rs2_dat_o = {DATA_WIDTH{1'b0}};
            rs2_dat_sel_o = 1'b0;
        end
    end

endmodule
