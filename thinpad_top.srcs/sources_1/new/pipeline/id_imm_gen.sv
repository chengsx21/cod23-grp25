module id_imm_gen #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] inst_i,
    output logic [DATA_WIDTH-1:0] imm_o
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
        MINU = 6'b010110
    } Opcode_t;
    Opcode_t op;

    logic [6:0] opcode;
    logic [6:0] func7;
    logic [2:0] func3;
    logic [4:0] rs2;

    assign opcode = inst_i[6:0];
    assign func7 = inst_i[31:25];
    assign func3 = inst_i[14:12];
    assign rs2 = inst_i[24:20];

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
                else if (func3 == 3'b001 && func7 == 7'b0110000 && rs2 == 5'b00010) begin
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

            default: begin
                op = DEFAULT;
            end
        endcase
    end

    always_comb begin
        imm_o = {DATA_WIDTH{1'b0}};

        case (op)
            ADD: begin
                imm_o = {DATA_WIDTH{1'b0}};
            end

            ADDI: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            AND: begin
                imm_o = {DATA_WIDTH{1'b0}};
            end

            ANDI: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            AUIPC: begin
                imm_o = {inst_i[31:12], 12'b0};
            end

            BEQ: begin
                imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            end

            BNE: begin
                imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            end

            JAL: begin
                imm_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end

            JALR: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            LB: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            LUI: begin
                imm_o = {inst_i[31:12], 12'b0};
            end

            LW: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            OR: begin
                imm_o = {DATA_WIDTH{1'b0}};
            end

            ORI: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            SB: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            end

            SLLI: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            SRLI: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            SW: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            end

            XOR: begin
                imm_o = {DATA_WIDTH{1'b0}};
            end

            PCNT: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            PACK: begin
                imm_o = {DATA_WIDTH{1'b0}};
            end

            MINU: begin
                imm_o = {DATA_WIDTH{1'b0}};
            end

        endcase
    end
endmodule
