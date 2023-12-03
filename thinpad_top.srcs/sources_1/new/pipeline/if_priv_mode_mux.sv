module if_priv_mode_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire exception_en_i,
    input wire [1:0] if_privilege_mode_i,
    input wire [1:0] exception_privilege_mode_i,
    output logic [1:0] privilege_mode_o
    );
    
    always_comb begin
        if (exception_en_i) begin
            privilege_mode_o = exception_privilege_mode_i;
        end
        else begin
            privilege_mode_o = if_privilege_mode_i;
        end
    end
endmodule
