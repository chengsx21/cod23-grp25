module if_inst_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] cache_inst_i,
    input wire [DATA_WIDTH-1:0] mem_inst_i,
    input wire cache_en_i,
    output reg [DATA_WIDTH-1:0] inst_o
);

    assign inst_o = cache_en_i ? cache_inst_i : mem_inst_i;

endmodule