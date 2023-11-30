module jump_predict #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire [ADDR_WIDTH-1:0] if_pc_i,
    input wire [DATA_WIDTH-1:0] if_inst_i,
    output reg [ADDR_WIDTH-1:0] if_next_pc_o,
    output reg if_predict_o,

    input wire [ADDR_WIDTH-1:0] exe_pc_i,
    input wire br_predict_i,
    input wire [ADDR_WIDTH-1:0] br_target_i,
    input wire br_taken_i,
    input wire br_en_i,
    input wire [2:0] br_op_i,
    
    output reg br_miss_o,
    output reg [ADDR_WIDTH-1:0] br_next_o
);

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

    reg [15:0][ADDR_WIDTH-1:0] br_addr_table;
    reg [15:0][ADDR_WIDTH-1:0] next_pc_table;
    reg [15:0] history_table;
    reg [15:0] valid_table;
    wire [6:0] opcode;
    wire [2:0] func3;

    assign opcode = if_inst_i[6:0];
    assign func3 = if_inst_i[14:12];

    always_comb begin
        op = DEFAULT;
        if (opcode == 7'b1100011) begin
            if (func3 == 3'b000) begin
                op = BEQ;
            end
            else if (func3 == 3'b001) begin
                op = BNE;
            end
        end
        else if (opcode == 7'b1101111) begin
            op = JAL;
        end
    end

    always_comb begin
        if_next_pc_o = if_pc_i + 4;
        if_predict_o = 1'b0;
        if (op != DEFAULT && valid_table[if_pc_i[5:2]] && br_addr_table[if_pc_i[5:2]] == if_pc_i && history_table[if_pc_i[5:2]]) begin
            if_next_pc_o = next_pc_table[if_pc_i[5:2]];
            if_predict_o = 1'b1;
        end
    end

    always_comb begin
        br_miss_o = 1'b0;
        br_next_o = {ADDR_WIDTH{1'b0}};
        if (br_en_i) begin
            br_miss_o = br_taken_i != br_predict_i;
            br_next_o = br_taken_i ? br_target_i : exe_pc_i + 4;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                br_addr_table[i] <= {ADDR_WIDTH{1'b0}};
                next_pc_table[i] <= {ADDR_WIDTH{1'b0}};
                history_table[i] <= 1'b0;
                valid_table[i] <= 1'b0;
            end
        end
        else begin
            if (br_en_i && br_op_i != 3'b100) begin
                br_addr_table[exe_pc_i[5:2]] <= exe_pc_i;
                next_pc_table[exe_pc_i[5:2]] <= br_target_i;
                history_table[exe_pc_i[5:2]] <= br_taken_i;
                valid_table[exe_pc_i[5:2]] <= 1'b1;
            end
        end
    end    

endmodule