module if_id_regs #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,

    // [ID] ~ [EXE]
    input wire [DATA_WIDTH-1:0] inst_i,
    output logic [DATA_WIDTH-1:0] inst_o,

    // [EXE] ~ [MEM]
    input wire [DATA_WIDTH-1:0] pc_i,
    output logic [DATA_WIDTH-1:0] pc_o
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            inst_o <= 0;
            pc_o <= 0;
        end else if (stall_i) begin
            // Do nothing   
        end else if (bubble_i) begin
            inst_o <= 0;
            pc_o <= 0;
        end else begin
            inst_o <= inst_i;
            pc_o <= pc_i;
        end
    end
endmodule
