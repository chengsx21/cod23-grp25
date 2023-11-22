module if_pc_mux #(
    parameter ADDR_WIDTH = 32
) (
    input wire [ADDR_WIDTH-1:0] alu_y_i,
    input wire [ADDR_WIDTH-1:0] pc_current_i,
    input wire pc_sel_i,
    output logic [ADDR_WIDTH-1:0] pc_next_o
    );

    always_comb begin
        if (pc_sel_i) begin
            pc_next_o = alu_y_i;
        end
        else begin
            pc_next_o = pc_current_i + 4;
        end
    end
endmodule
