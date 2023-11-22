module id_reg_file #(
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire we_i,
    input wire [4:0] waddr_i,
    input wire [DATA_WIDTH-1:0] wdata_i,
    input wire [4:0] raddr_a_i,
    output reg [DATA_WIDTH-1:0] rdata_a_o,
    input wire [4:0] raddr_b_i,
    output reg [DATA_WIDTH-1:0] rdata_b_o
    );

    reg [31:0][DATA_WIDTH-1:0] regs;

    always_comb begin
        // Read data
        rdata_a_o = regs[raddr_a_i];
        rdata_b_o = regs[raddr_b_i];
    end

    always_ff @(posedge clk_i) begin
        // Reset
        if (rst_i) begin
            for (integer i = 0; i < 32; i = i + 1) begin
                regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        // Write data
        else if (we_i && (waddr_i != 0)) begin
            regs[waddr_i] <= wdata_i;
        end
    end

endmodule
