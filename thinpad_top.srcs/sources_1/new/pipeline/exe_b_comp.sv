module exe_b_comp #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [DATA_WIDTH-1:0] rs2_dat_i,
    input wire br_op_i,
    output reg br_cond_o
    );

    always_comb begin
        br_cond_o = 1'b0;
        // 0 For No Branch, 1 For Beq Branch
        if (br_op_i == 1'b1) begin
            br_cond_o = (rs1_dat_i == rs2_dat_i);
        end
    end
endmodule
