module exe_b_comp #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [DATA_WIDTH-1:0] rs2_dat_i,
    input wire [2:0] br_op_i,
    output reg br_taken_o,
    output reg br_en_o
);

    always_comb begin
        br_taken_o = 1'b0;
        br_en_o = 1'b0;
        // 0 For No Branch, 1 For Beq Branch, 2 For Bne Branch, 3 For Jal, 4 For Jalr
        if (br_op_i == 3'b001) begin
            br_taken_o = rs1_dat_i == rs2_dat_i;
            br_en_o = 1'b1;
        end
        else if (br_op_i == 3'b010) begin
            br_taken_o = rs1_dat_i != rs2_dat_i;
            br_en_o = 1'b1;
        end
        else if (br_op_i == 3'b011) begin
            br_taken_o = 1'b1;
            br_en_o = 1'b1;
        end
        else if (br_op_i == 3'b100) begin
            br_taken_o = 1'b1;
            br_en_o = 1'b1;
        end
    end

endmodule
