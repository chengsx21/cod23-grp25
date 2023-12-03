module id_decoder #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] inst_i,

    // [ID] ~ [EXE]
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,

    output logic [2:0] br_op_o,
    output logic [1:0] alu_a_mux_sel_o, // 0 For Rs1, 1 For PC, 2 For Zero, 3 For CSR
    output logic [1:0] alu_b_mux_sel_o, // 0 For Rs2, 1 For Imm, 2 For Zero
    output logic [3:0] alu_op_o,

    // [EXE] ~ [MEM]
    output logic dm_en_o,
    output logic dm_we_o,
    output logic [2:0] dm_dat_width_o,
    output logic [1:0] writeback_mux_sel_o, // 0 For DM, 1 For ALU, 2 For PC+4

    // [MEM] ~ [WRITEBACK]
    output logic [4:0] rd_o,
    output logic reg_we_o,

    // [CSR]
    output logic csr_we_o,
    output logic [1:0] csr_op_o, // 0 For Write, 1 For Set, 2 For Clear
    output logic [11:0] csr_addr_o,

    output logic mret_en_o,
    output logic ecall_ebreak_en_o,
    output logic exception_type_o, // 1 For Interrupt, 0 For Exception
    output logic [DATA_WIDTH-1:0] exception_code_o,
    output logic [1:0] exception_privilege_mode_o,

    output logic [1:0] instruction_mode_o
    );

    // Follow the format of `lab3_tb.sv`
    typedef enum logic [5:0] {
        DEFAULT = 6'b000000,
        ADD = 6'b000001,
        ADDI = 6'b000010,
        AND = 6'b000011,
        ANDI = 6'b000100,
        AUIPC = 6'b000101,
        BEQ = 6'b000110,
        BNE = 6'b000111,
        JAL = 6'b001000,
        JALR = 6'b001001,
        LB = 6'b001010,
        LUI = 6'b001011,
        LW = 6'b001100,
        OR = 6'b001101,
        ORI = 6'b001110,
        SB = 6'b001111,
        SLLI = 6'b010000,
        SRLI = 6'b010001,
        SW = 6'b010010,
        XOR = 6'b010011,
        PCNT = 6'b010100,
        PACK = 6'b010101,
        MINU = 6'b010110,
        CSRRW = 6'b010111,
        CSRRS = 6'b011000,
        CSRRC = 6'b011001,
        EBREAK = 6'b011010,
        ECALL = 6'b011011,
        MRET = 6'b011100,
        SLTU = 6'b011101
    } Opcode_t;
    Opcode_t op;

    assign rs1_o = inst_i[19:15];
    assign rs2_o = inst_i[24:20];
    assign rd_o = inst_i[11:7];
    assign csr_addr_o = inst_i[31:20];

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
                else if (func3 == 3'b001) begin
                    op = BNE;
                end
            end

            7'b0000011: begin
                if (func3 == 3'b000) begin
                    op = LB;
                end
                else if (func3 == 3'b010) begin
                    op = LW;
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
                else if (func3 == 3'b110) begin
                    op = ORI;
                end
                else if (func3 == 3'b001 && func7 == 7'b0000000) begin
                    op = SLLI;
                end
                else if (func3 == 3'b101 && func7 == 7'b0000000) begin
                    op = SRLI;
                end
                else if (func3 == 3'b001 && func7 == 7'b0110000 && rs2_o == 5'b00010) begin
                    op = PCNT;
                end
            end

            7'b0110011: begin
                if (func3 == 3'b000 && func7 == 7'b0000000) begin
                    op = ADD;
                end
                else if (func3 == 3'b111 && func7 == 7'b0000000) begin
                    op = AND;
                end
                else if (func3 == 3'b110 && func7 == 7'b0000000) begin
                    op = OR;
                end
                else if (func3 == 3'b100 && func7 == 7'b0000000) begin
                    op = XOR;
                end
                else if (func3 == 3'b100 && func7 == 7'b0000100) begin
                    op = PACK;
                end
                else if (func3 == 3'b110 && func7 == 7'b0000101) begin
                    op = MINU;
                end
                else if (func3 == 3'b011 && func7 == 7'b0000000) begin
                    op = SLTU;
                end
            end

            7'b0010111: begin
                op = AUIPC;
            end

            7'b1101111: begin
                op = JAL;
            end

            7'b1100111: begin
                if (func3 == 3'b000) begin
                    op = JALR;
                end
            end

            7'b1110011: begin
                if (func3 == 3'b001) begin
                    op = CSRRW;
                end
                else if (func3 == 3'b010) begin
                    op = CSRRS;
                end
                else if (func3 == 3'b011) begin
                    op = CSRRC;
                end
                else if (inst_i == 32'b00000000_00010000_00000000_01110011) begin
                    op = EBREAK;
                end
                else if (inst_i == 32'b00000000_00000000_00000000_01110011) begin
                    op = ECALL;
                end
                else if (inst_i == 32'b00110000_00100000_00000000_01110011) begin
                    op = MRET;
                end
            end

            default: begin
                op = DEFAULT;
            end
        endcase
    end

    always_comb begin
        br_op_o = 3'b000;
        alu_a_mux_sel_o = 2'b10;
        alu_b_mux_sel_o = 2'b10;
        alu_op_o = 4'b0000;

        dm_en_o = 1'b0;
        dm_we_o = 1'b0;
        dm_dat_width_o = 3'b100;
        writeback_mux_sel_o = 2'b01;

        reg_we_o = 1'b0;

        csr_we_o = 1'b0;
        csr_op_o = 2'b00;

        mret_en_o = 1'b0;
        ecall_ebreak_en_o = 1'b0;
        exception_type_o = 1'b0;
        exception_code_o = {DATA_WIDTH{1'b0}};
        exception_privilege_mode_o = 2'b00;

        instruction_mode_o = 2'b00;

        case (op)
            ADD: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            ADDI: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            AND: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b0011;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            ANDI: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0011;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            AUIPC: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            BEQ: begin
                br_op_o = 3'b001;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;
            end

            BNE: begin
                br_op_o = 3'b010;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;
            end

            JAL: begin
                br_op_o = 3'b011;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b10;

                reg_we_o = 1'b1;
            end

            JALR: begin
                br_op_o = 3'b100;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b10;

                reg_we_o = 1'b1;
            end

            LB: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b1;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b001;
                writeback_mux_sel_o = 2'b00;

                reg_we_o = 1'b1;
            end

            LUI: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b10;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            LW: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b1;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b00;

                reg_we_o = 1'b1;
            end

            OR: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b0100;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            ORI: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0100;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            SB: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b1;
                dm_we_o = 1'b1;
                dm_dat_width_o = 3'b001;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;
            end

            SLLI: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0111;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            SRLI: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b1000;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            SW: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b1;
                dm_we_o = 1'b1;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;
            end

            XOR: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b0101;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            PCNT: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b1011;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            PACK: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b1100;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            MINU: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b1101;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end
            
            SLTU: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b00;
                alu_b_mux_sel_o = 2'b00;
                alu_op_o = 4'b1110;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;
            end

            CSRRW: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b11;
                alu_b_mux_sel_o = 2'b10;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = (rd_o != 5'b00000);

                csr_we_o = 1'b1;
                csr_op_o = 2'b00;

                instruction_mode_o = 2'b11;
            end

            CSRRS: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b11;
                alu_b_mux_sel_o = 2'b10;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;

                csr_we_o = (rs1_o != 5'b00000);
                csr_op_o = 2'b01;

                instruction_mode_o = 2'b11;
            end

            CSRRC: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b11;
                alu_b_mux_sel_o = 2'b10;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b1;

                csr_we_o = (rs1_o != 5'b00000);
                csr_op_o = 2'b10;

                instruction_mode_o = 2'b11;
            end

            EBREAK: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;

                ecall_ebreak_en_o = 1'b1;
                exception_type_o = 1'b0;
                exception_code_o = 32'h3;
                exception_privilege_mode_o = 2'b11;

                instruction_mode_o = 2'b11;
            end

            ECALL: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;

                ecall_ebreak_en_o = 1'b1;
                exception_type_o = 1'b0;
                exception_code_o = 32'h8;
                exception_privilege_mode_o = 2'b11;

                instruction_mode_o = 2'b11;
            end

            MRET: begin
                br_op_o = 3'b000;
                alu_a_mux_sel_o = 2'b01;
                alu_b_mux_sel_o = 2'b01;
                alu_op_o = 4'b0001;

                dm_en_o = 1'b0;
                dm_we_o = 1'b0;
                dm_dat_width_o = 3'b100;
                writeback_mux_sel_o = 2'b01;

                reg_we_o = 1'b0;

                mret_en_o = 1'b1;
                exception_privilege_mode_o = 2'b00;

                instruction_mode_o = 2'b11;
            end
        endcase
    end
endmodule
