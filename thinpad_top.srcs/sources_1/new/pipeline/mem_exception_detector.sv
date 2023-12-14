module mem_exception_detector #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire exception_en_i,
    input wire [ADDR_WIDTH-1:0] exception_pc_i,         // PC for next IF Instruction if Exception
    input wire [1:0] exception_privilege_mode_i,        // Privilege Mode for next IF Instruction

    input wire interrupt_en_i,
    input wire [ADDR_WIDTH-1:0] interrupt_pc_i,         // PC for next IF Instruction if Interrupt

    input wire mem_load_fault_en_i,
    input wire [ADDR_WIDTH-1:0] mem_load_fault_pc_i,
    input wire mem_store_fault_en_i,
    input wire [ADDR_WIDTH-1:0] mem_store_fault_pc_i,

    input wire load_misalign_en_i, 
    input wire [ADDR_WIDTH-1:0] load_misalign_pc_i,
    input wire store_misalign_en_i,
    input wire [ADDR_WIDTH-1:0] store_misalign_pc_i,

    output logic csr_exception_en_o,                    // Exception/Interrupt Enable
    output logic [ADDR_WIDTH-1:0] csr_exception_pc_o,   // PC for next IF Instruction if Exception/Interrupt
    output logic [1:0] csr_exception_privilege_mode_o   // Privilege Mode for next IF Instruction if Exception/Interrupt
);

    always_comb begin
        if (mem_load_fault_en_i) begin
            csr_exception_en_o = 1'b1;
            csr_exception_pc_o = mem_load_fault_pc_i;
            csr_exception_privilege_mode_o = 2'b11;
        end
        else if (mem_store_fault_en_i) begin
            csr_exception_en_o = 1'b1;
            csr_exception_pc_o = mem_store_fault_pc_i;
            csr_exception_privilege_mode_o = 2'b11;
        end
        else if (load_misalign_en_i) begin
            csr_exception_en_o = 1'b1;
            csr_exception_pc_o = load_misalign_pc_i;
            csr_exception_privilege_mode_o = 2'b11;
        end
        else if (store_misalign_en_i) begin
            csr_exception_en_o = 1'b1;
            csr_exception_pc_o = store_misalign_pc_i;
            csr_exception_privilege_mode_o = 2'b11;
        end
        else begin
            csr_exception_en_o = exception_en_i | interrupt_en_i;
            csr_exception_pc_o = (interrupt_en_i? interrupt_pc_i: exception_pc_i);
            csr_exception_privilege_mode_o = (interrupt_en_i? 2'b11: exception_privilege_mode_i);
        end
    end

endmodule
