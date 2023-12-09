module if_inst_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] cache_inst_i,
    input wire [DATA_WIDTH-1:0] mem_inst_i,
    input wire cache_en_i,
    output reg [DATA_WIDTH-1:0] inst_o,
    output reg clear_cache_o
);

    wire [DATA_WIDTH-1:0] origin_inst;

    assign origin_inst = cache_en_i ? cache_inst_i : mem_inst_i;
    assign inst_o = origin_inst == 32'b0000_0000_0000_0000_0001_0000_0000_1111 ? 32'b0000_0000_0100_0000_0000_0000_0110_1111 : origin_inst;
    assign clear_cache_o = origin_inst == 32'b0000_0000_0000_0000_0001_0000_0000_1111 ? 1'b1 : 1'b0;

endmodule