module id_rdata_b_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] forward_rdata_b_i,
    input wire [DATA_WIDTH-1:0] rdata_b_i,
    input wire forward_rdata_b_sel_i,
    output logic [DATA_WIDTH-1:0] rdata_b_o
    );

    always_comb begin
        if (forward_rdata_b_sel_i) begin
            rdata_b_o = forward_rdata_b_i;
        end
        else begin
            rdata_b_o = rdata_b_i;
        end
    end

endmodule
