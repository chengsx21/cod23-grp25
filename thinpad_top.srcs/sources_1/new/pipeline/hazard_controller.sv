module hazard_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire im_ready_i,
    input wire dm_ready_i,

    input wire [4:0] id_rs1_i,
    input wire [4:0] id_rs2_i,
    input wire [4:0] exe_rd_i,
    input wire [4:0] mem_rd_i,
    input wire [4:0] writeback_rd_i,

    input wire br_miss_i,
    input wire cache_en_i,
    input wire exe_reg_we_i,
    input wire mem_reg_we_i,
    input wire writeback_reg_we_i,

    input wire exe_dm_en_i,
    input wire exe_dm_we_i,

    input wire [ADDR_WIDTH-1:0] if_pc_i,
    input wire [ADDR_WIDTH-1:0] id_pc_i,
    input wire [ADDR_WIDTH-1:0] exe_pc_i,
    input wire [ADDR_WIDTH-1:0] alu_y_i,

    input wire [1:0] id_instruction_mode_i,
    input wire [1:0] exe_instruction_mode_i,
    input wire [1:0] mem_instruction_mode_i,
    input wire [1:0] writeback_instruction_mode_i,

    input wire exception_en_i,
    input wire interrupt_en_i,

    output logic pc_sel_o,
    output logic pc_stall_o,
    output logic if_id_stall_o,
    output logic if_id_bubble_o,
    output logic id_exe_stall_o,
    output logic id_exe_bubble_o,
    output logic exe_mem_stall_o,
    output logic exe_mem_bubble_o,
    output logic mem_wb_stall_o,
    output logic mem_wb_bubble_o
    );

    wire exe_raw_stall;
    wire mem_raw_stall;
    wire writeback_raw_stall;
    
    typedef enum logic [2:0] {
        NONE = 3'b000,
        IN = 3'b001,
        DM = 3'b010,
        BR = 3'b011,
        RW = 3'b100,
        EX = 3'b101,
        IM = 3'b110
    } hazard_t;
    hazard_t hazard_type;

    assign pc_sel_o = br_miss_i;

    logic csr_mode;
    assign csr_mode = (id_instruction_mode_i == 2'b11) || (exe_instruction_mode_i == 2'b11) || (mem_instruction_mode_i == 2'b11) || (writeback_instruction_mode_i == 2'b11);

    always_comb begin
        pc_stall_o = 0;
        if_id_stall_o = 0;
        id_exe_stall_o = 0;
        exe_mem_stall_o = 0;
        mem_wb_stall_o = 0;

        if_id_bubble_o = 0;
        id_exe_bubble_o = 0;
        exe_mem_bubble_o = 0;
        mem_wb_bubble_o = 0;

        hazard_type = NONE;

        //* Timer Interrupt *//
        //* Flush the whole pipeline *//
        if (interrupt_en_i) begin
            pc_stall_o = 0;
            if_id_stall_o = 0;
            id_exe_stall_o = 0;
            exe_mem_stall_o = 0;
            mem_wb_stall_o = 0;

            if_id_bubble_o = 1;
            id_exe_bubble_o = 1;
            exe_mem_bubble_o = 1;
            mem_wb_bubble_o = 1;

            hazard_type = IN;
        end

        //* DM not Ready *//
        //* Wait for DM to be Ready *//
        else if (~dm_ready_i) begin
            pc_stall_o = 1;
            if_id_stall_o = 1;
            id_exe_stall_o = 1;
            exe_mem_stall_o = 1;
            mem_wb_stall_o = 0;

            if_id_bubble_o = 0;
            id_exe_bubble_o = 0;
            exe_mem_bubble_o = 0;
            mem_wb_bubble_o = 1;

            hazard_type = DM;
        end

        //* PC Branch *//
        else if (pc_sel_o) begin
            pc_stall_o = 0;
            if_id_stall_o = 0;
            id_exe_stall_o = 0;
            exe_mem_stall_o = 0;
            mem_wb_stall_o = 0;

            if_id_bubble_o = 1;
            id_exe_bubble_o = 1;
            exe_mem_bubble_o = 0;
            mem_wb_bubble_o = 0;

            hazard_type = BR;
        end

        //* Read after Write Hazard *//
        //* Wait for WriteBack to be Done *//
        else if (exe_dm_en_i && (~exe_dm_we_i)) begin
            pc_stall_o = 1;
            if_id_stall_o = 1;
            id_exe_stall_o = 0;
            exe_mem_stall_o = 0;
            mem_wb_stall_o = 0;

            if_id_bubble_o = 0;
            id_exe_bubble_o = 1;
            exe_mem_bubble_o = 0;
            mem_wb_bubble_o = 0;

            hazard_type = RW;
        end

        //* CSR Instr *//
        //* Stall the whole pipeline *//
        else if (csr_mode) begin
            if (exception_en_i) begin
                pc_stall_o = 0;
            end
            else begin
                pc_stall_o = 1;
            end
            if_id_stall_o = 0;
            id_exe_stall_o = 0;
            exe_mem_stall_o = 0;
            mem_wb_stall_o = 0;

            if_id_bubble_o = 1;
            id_exe_bubble_o = 0;
            exe_mem_bubble_o = 0;
            mem_wb_bubble_o = 0;

            hazard_type = EX;
        end

        //* IM not Ready *//
        //* May Cause Branch while Fetch, See in `if_im_master.sv` *//
        else if (~im_ready_i) begin
            pc_stall_o = 1;
            if_id_stall_o = 0;
            id_exe_stall_o = 0;
            exe_mem_stall_o = 0;
            mem_wb_stall_o = 0;

            if_id_bubble_o = 1;
            id_exe_bubble_o = 0;
            exe_mem_bubble_o = 0;
            mem_wb_bubble_o = 0;

            hazard_type = IM;
        end
    end

endmodule
