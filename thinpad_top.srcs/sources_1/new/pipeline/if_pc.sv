module if_pc_reg #(
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire pc_stall_i,
    input wire [DATA_WIDTH-1:0] pc_next_i,
    input wire [1:0] privilege_mode_i,

    output reg [DATA_WIDTH-1:0] pc_current_o,
    output logic [1:0] privilege_mode_o
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_current_o <= 32'h8000_0000;
            privilege_mode_o <= 2'b11;
        end else if (pc_stall_i) begin
            // Do nothing
        end else begin
            pc_current_o <= pc_next_i;
            privilege_mode_o <= privilege_mode_i;
        end
    end
endmodule
