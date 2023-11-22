module exe_alu_a_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire [1:0] alu_a_sel_i,
    output reg [DATA_WIDTH-1:0] alu_a_o
    );

    always_comb begin
        alu_a_o = {DATA_WIDTH{1'b0}};
        case (alu_a_sel_i)
            // 0 For Rs1, 1 For PC, 2 For Zero
            2'b00: begin
                alu_a_o = rs1_dat_i;
            end

            2'b01: begin
                alu_a_o = pc_i;
            end

            default: begin
                alu_a_o = {DATA_WIDTH{1'b0}};
            end
        endcase
    end
endmodule
