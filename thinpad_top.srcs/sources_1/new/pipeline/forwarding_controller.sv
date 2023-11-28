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

    input wire [DATA_WIDTH-1:0] exe_alu_y_i,
    input wire [DATA_WIDTH-1:0] mem_alu_y_i,
    input wire [DATA_WIDTH-1:0] writeback_data_i,

    input wire [1:0] exe_writeback_mux_sel_i,
    input wire [1:0] mem_writeback_mux_sel_i
    );
endmodule
