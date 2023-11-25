module exe_b_comp #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [DATA_WIDTH-1:0] rs2_dat_i,
    input wire [1:0] br_op_i,
    output reg br_cond_o
    );

    always_comb begin
        br_cond_o = 1'b0;
        // 0 For No Branch, 1 For Beq Branch, 2 For Beq Branch, 3 For Unconditional Jump
        if (br_op_i == 2'b01) begin
            br_cond_o = (rs1_dat_i == rs2_dat_i);
        end
        else if (br_op_i == 2'b10) begin
            br_cond_o = (rs1_dat_i != rs2_dat_i);
        end
        else if (br_op_i == 2'b11) begin
            br_cond_o = 1'b1;
        end
    end
endmodule
