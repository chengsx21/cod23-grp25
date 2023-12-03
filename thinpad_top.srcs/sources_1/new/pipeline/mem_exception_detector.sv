module mem_exception_detector #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire exception_en_i,
    input wire [ADDR_WIDTH-1:0] exception_pc_i,
    input wire [1:0] exception_privilege_mode_i,

    output logic csr_exception_en_o,
    output logic [ADDR_WIDTH-1:0] csr_exception_pc_o,
    output logic [1:0] csr_exception_privilege_mode_o
    );

    assign csr_exception_en_o = exception_en_i;
    assign csr_exception_pc_o = exception_pc_i;
    assign csr_exception_privilege_mode_o = exception_privilege_mode_i;

endmodule
