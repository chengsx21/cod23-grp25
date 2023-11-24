module id_exe_regs #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,

    // [ID] ~ [EXE]
    input wire [DATA_WIDTH-1:0] inst_i,
    output logic [DATA_WIDTH-1:0] inst_o,
    input wire [DATA_WIDTH-1:0] imm_i,
    output logic [DATA_WIDTH-1:0] imm_o, 
    input wire [4:0] rs1_i,
    output logic [4:0] rs1_o,
    input wire [4:0] rs2_i,
    output logic [4:0] rs2_o,

    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    output logic [DATA_WIDTH-1:0] rs1_dat_o,
    input wire [1:0] br_op_i,
    output logic [1:0] br_op_o,
    input wire [1:0] alu_a_mux_sel_i,
    output logic [1:0] alu_a_mux_sel_o,
    input wire [1:0] alu_b_mux_sel_i,
    output logic [1:0] alu_b_mux_sel_o,
    input wire [3:0] alu_op_i,
    output logic [3:0] alu_op_o,


    // [EXE] ~ [MEM]
    input wire [DATA_WIDTH-1:0] pc_i,
    output logic [DATA_WIDTH-1:0] pc_o,
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
    output logic reg_we_o
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            inst_o <= 0;
            imm_o <= 0;
            rs1_o <= 0;
            rs2_o <= 0;
            rs1_dat_o <= 0;
            br_op_o <= 0;
            // 0 For Rs1, 1 For PC, 2 For Zero
            alu_a_mux_sel_o <= 2;
            alu_b_mux_sel_o <= 2;
            // 0 For Nothing
            alu_op_o <= 0;

            pc_o <= 0;
            rs2_dat_o <= 0;
            dm_en_o <= 0;
            dm_we_o <= 0;
            dm_dat_width_o <= 4;
            writeback_mux_sel_o <= 1; // ALU

            rd_o <= 0;
            reg_we_o <= 0;
        end else if (stall_i) begin
            // Do nothing   
        end else if (bubble_i) begin
            inst_o <= 0;
            imm_o <= 0;
            rs1_o <= 0;
            rs2_o <= 0;
            rs1_dat_o <= 0;
            br_op_o <= 0;
            // 0 For Rs1, 1 For PC, 2 For Zero
            alu_a_mux_sel_o <= 2;
            alu_b_mux_sel_o <= 2;
            // 0 For Nothing
            alu_op_o <= 0;

            pc_o <= 0;
            rs2_dat_o <= 0;
            dm_en_o <= 0;
            dm_we_o <= 0;
            dm_dat_width_o <= 4;
            writeback_mux_sel_o <= 1; // ALU

            rd_o <= 0;
            reg_we_o <= 0;
        end else begin
            inst_o <= inst_i;
            imm_o <= imm_i;
            rs1_o <= rs1_i;
            rs2_o <= rs2_i;
            rs1_dat_o <= rs1_dat_i;
            br_op_o <= br_op_i;
            alu_a_mux_sel_o <= alu_a_mux_sel_i;
            alu_b_mux_sel_o <= alu_b_mux_sel_i;
            alu_op_o <= alu_op_i;

            pc_o <= pc_i;
            rs2_dat_o <= rs2_dat_i;
            dm_en_o <= dm_en_i;
            dm_we_o <= dm_we_i;
            dm_dat_width_o <= dm_dat_width_i;
            writeback_mux_sel_o <= writeback_mux_sel_i;

            rd_o <= rd_i;
            reg_we_o <= reg_we_i;
        end
    end
endmodule
