module if_pc_mux #(
    parameter ADDR_WIDTH = 32
) (
    input wire [ADDR_WIDTH-1:0] pc_if,
    input wire [ADDR_WIDTH-1:0] pc_exe,
    input wire [ADDR_WIDTH-1:0] pc_exception,
    input wire exception_en_i,
    input wire pc_sel_i,
    output logic [ADDR_WIDTH-1:0] pc_next_o
    );

    always_comb begin
        if (exception_en_i) begin
            pc_next_o = pc_exception;
        end
        else if (pc_sel_i) begin
            pc_next_o = pc_exe;
        end
        else begin
            pc_next_o = pc_if;
        end
    end
endmodule
