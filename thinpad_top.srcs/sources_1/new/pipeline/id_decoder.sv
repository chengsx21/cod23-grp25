module id_decoder #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] inst_i,

    // [ID] ~ [EXE]
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,

    output logic br_op_o,
    output logic [1:0] alu_a_mux_sel_o, // 0 For Rs1, 1 For PC, 2 For Zero
    output logic [1:0] alu_b_mux_sel_o, // 0 For Rs2, 1 For Imm, 2 For Zero
    output logic [3:0] alu_op_o,

    // [EXE] ~ [MEM]
    output logic dm_en_o,
    output logic dm_we_o,
    output logic [2:0] dm_dat_width_o,
    output logic [1:0] writeback_mux_sel_o, // 0 For DM, 1 For ALU, 2 For PC+4

    // [MEM] ~ [WRITEBACK]
    output logic [4:0] rd_o,
    output logic reg_we_o
    );

    // Follow the format of `lab3_tb.sv`
    typedef enum logic [3:0] {
        LUI = 4'b0001,
        BEQ = 4'b0010,
        LB = 4'b0011,
        SB  = 4'b0100,
        SW = 4'b0101,
        ADDI = 4'b0110,
        ANDI = 4'b0111,
        ADD = 4'b1000,
        DEFAULT = 4'b1010
    } Opcode_t;
    Opcode_t op;

    assign rs1_o = inst_i[19:15];
    assign rs2_o = inst_i[24:20];
    assign rd_o = inst_i[11:7];

    logic [6:0] opcode;
    logic [6:0] func7;
    logic [2:0] func3;

    assign opcode = inst_i[6:0];
    assign func7 = inst_i[31:25];
    assign func3 = inst_i[14:12];

    always_comb begin
        op = DEFAULT;
        case (opcode)
            7'b0110111: begin
                op = LUI;
            end

            7'b1100011: begin
                if (func3 == 3'b000) begin
                    op = BEQ;
                end
            end

            7'b0000011: begin
                if (func3 == 3'b000) begin
                    op = LB;
                end
            end

            7'b0100011: begin
                if (func3 == 3'b000) begin
                    op = SB;
                end
                else if (func3 == 3'b010) begin
                    op = SW;
                end
            end

            7'b0010011: begin
                if (func3 == 3'b000) begin
                    op = ADDI;
                end
                else if (func3 == 3'b111) begin
                    op = ANDI;
                end
            end

            7'b0110011: begin
                if (func3 == 3'b000 && func7 == 7'b0000000) begin
                    op = ADD;
                end
            end
            default: begin
                op = DEFAULT;
            end
        endcase
    end

    always_comb begin
        br_op_o = 1'b0;
        alu_a_mux_sel_o = 2'b10;
        alu_b_mux_sel_o = 2'b10;
        alu_op_o = 4'b0000;

        dm_en_o = 1'b0;
        dm_we_o = 1'b0;
        dm_dat_width_o = 3'b100;
        writeback_mux_sel_o = 2'b01;

        reg_we_o = 1'b0;

        case (op)
            LUI: begin
                br_op_o = 1'b0;
                alu_a_mux_sel_o = 2'b10;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            BEQ: begin
                br_op_o = 1'b1;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;
            end

            LB: begin
                br_op_o = 1'b0;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b1;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b001;
                writeback_mux_sel_o = 2'b00;

                reg_we_o = 1'b1;
            end

            SB: begin
                br_op_o = 1'b0;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b1;
                dm_we_o = 1'b1;
                dm_dat_width_o = 3'b001;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;
            end

            SW: begin
                br_op_o = 1'b0;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b1;
                dm_we_o = 1'b1;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;
            end

            ADDI: begin
                br_op_o = 1'b0;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            ANDI: begin
                br_op_o = 1'b0;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0011;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            ADD: begin
                br_op_o = 1'b0;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end
        endcase
    end
endmodule
