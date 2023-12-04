module mem_exception_detector #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire exception_en_i,
    input wire [ADDR_WIDTH-1:0] exception_pc_i,         // PC for next IF Instruction if Exception
    input wire [1:0] exception_privilege_mode_i,        // Privilege Mode for next IF Instruction

    input wire interrupt_en_i,
    input wire [ADDR_WIDTH-1:0] interrupt_pc_i,         // PC for next IF Instruction if Interrupt

    output logic csr_exception_en_o,                    // Exception/Interrupt Enable
    output logic [ADDR_WIDTH-1:0] csr_exception_pc_o,   // PC for next IF Instruction if Exception/Interrupt
    output logic [1:0] csr_exception_privilege_mode_o   // Privilege Mode for next IF Instruction if Exception/Interrupt
    );

    assign csr_exception_en_o = exception_en_i | interrupt_en_i;
    assign csr_exception_pc_o = (interrupt_en_i? interrupt_pc_i: exception_pc_i);
    assign csr_exception_privilege_mode_o = (interrupt_en_i? 2'b11: exception_privilege_mode_i);

endmodule
