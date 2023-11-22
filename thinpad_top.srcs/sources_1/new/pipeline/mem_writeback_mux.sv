module mem_writeback_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] dm_dat_i,
    input wire [DATA_WIDTH-1:0] alu_y_i,
    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire [1:0] writeback_mux_sel_i,
    output logic [DATA_WIDTH-1:0] writeback_mux_o
    );

    always_comb begin
        writeback_mux_o = 0;
        case (writeback_mux_sel_i)
            // 0 For DM, 1 For ALU, 2 For PC+4
            2'b00: begin
                writeback_mux_o = dm_dat_i;
            end
            2'b01: begin
                writeback_mux_o = alu_y_i;
            end
            2'b10: begin
                writeback_mux_o = pc_i + 4;
            end
            default: begin
                writeback_mux_o = 0;
            end
        endcase
    end
endmodule
