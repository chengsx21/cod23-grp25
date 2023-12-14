module if_icache #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire [ADDR_WIDTH-1:0] if_pc_i,
    output logic [DATA_WIDTH-1:0] if_r_inst_o,
    output logic if_cache_en_o,

    input wire exe_clear_cache_i,
    input wire if_cache_we_i,
    input wire [DATA_WIDTH-1:0] if_w_inst_i
);

    reg [15:0][ADDR_WIDTH-1:0] inst_addr_table;
    reg [15:0][DATA_WIDTH-1:0] inst_data_table;
    reg [15:0] valid_table;

    always_comb begin
        if_cache_en_o = 1'b0;
        if_r_inst_o = 32'h0000_0013;
        if (valid_table[if_pc_i[5:2]] && (inst_addr_table[if_pc_i[5:2]] == if_pc_i)) begin
            if_cache_en_o = 1'b1;
            if_r_inst_o = inst_data_table[if_pc_i[5:2]];
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                inst_addr_table[i] <= {ADDR_WIDTH{1'b0}};
                inst_data_table[i] <= {DATA_WIDTH{1'b0}};
                valid_table[i] <= 1'b0;
            end
        end
        else if (exe_clear_cache_i) begin
            valid_table <= 16'b0;
        end
        else if (if_cache_we_i) begin
            inst_addr_table[if_pc_i[5:2]] <= if_pc_i;
            inst_data_table[if_pc_i[5:2]] <= if_w_inst_i;
            valid_table[if_pc_i[5:2]] <= 1'b1;
        end
    end

endmodule