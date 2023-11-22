module exe_alu_b_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] rs2_dat_i,
    input wire [ADDR_WIDTH-1:0] imm_i,
    input wire [1:0] alu_b_sel_i,
    output reg [DATA_WIDTH-1:0] alu_b_o
    );

    always_comb begin
        alu_b_o = {DATA_WIDTH{1'b0}};
        case (alu_b_sel_i)
            // 0 For Rs2, 1 For Imm, 2 For Zero
            2'b00: begin
                alu_b_o = rs2_dat_i;
            end
            2'b01: begin
                alu_b_o = imm_i;
            end
            default: begin
                alu_b_o = {DATA_WIDTH{1'b0}};
            end
        endcase
    end
endmodule
