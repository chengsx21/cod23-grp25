module if_pc_reg #(
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire pc_stall_i,
    input wire [DATA_WIDTH-1:0] pc_next_i,
    output reg [DATA_WIDTH-1:0] pc_current_o
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_current_o <= 32'h8000_0000;
        end else if (pc_stall_i) begin
            // Do nothing
        end else begin
            pc_current_o <= pc_next_i;
        end
    end
endmodule
