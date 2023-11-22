module id_imm_gen #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] inst_i,
    output logic [DATA_WIDTH-1:0] imm_o
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
        imm_o = {DATA_WIDTH{1'b0}};

        case (op)
            LUI: begin
                imm_o = {inst_i[31:12], 12'b0};
            end

            BEQ: begin
                imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            end

            LB: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            SB: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            end

            SW: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            end

            ADDI: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            ANDI: begin
                imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end

            ADD: begin
                imm_o = {DATA_WIDTH{1'b0}};
            end
        endcase
    end
endmodule
