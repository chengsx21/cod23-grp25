module mem_writeback_regs #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,

    // [MEM] ~ [WRITEBACK]
    input wire [DATA_WIDTH-1:0] writeback_data_i,
    output logic [DATA_WIDTH-1:0] writeback_data_o,
    input wire [4:0] rd_i,
    output logic [4:0] rd_o,
    input wire reg_we_i,
    output logic reg_we_o
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            writeback_data_o <= 0;
            rd_o <= 0;
            reg_we_o <= 0;
        end else if (bubble_i) begin
            writeback_data_o <= 0;
            rd_o <= 0;
            reg_we_o <= 0;
        end else begin
            writeback_data_o <= writeback_data_i;
            rd_o <= rd_i;
            reg_we_o <= reg_we_i;
        end
    end
endmodule
