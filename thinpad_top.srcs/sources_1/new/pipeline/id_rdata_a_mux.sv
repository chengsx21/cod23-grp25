module id_rdata_a_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] forward_rdata_a_i,
    input wire [DATA_WIDTH-1:0] rdata_a_i,
    input wire forward_rdata_a_sel_i,
    output logic [DATA_WIDTH-1:0] rdata_a_o
    );

    always_comb begin
        if (forward_rdata_a_sel_i) begin
            rdata_a_o = forward_rdata_a_i;
        end
        else begin
            rdata_a_o = rdata_a_i;
        end
    end

endmodule
