module if_id_regs #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,

    // [ID] ~ [EXE]
    input wire [DATA_WIDTH-1:0] inst_i,
    output logic [DATA_WIDTH-1:0] inst_o,
    input wire predict_i,
    output logic predict_o,
    input wire clear_cache_i,
    output logic clear_cache_o,

    // [EXE] ~ [MEM]
    input wire [DATA_WIDTH-1:0] pc_i,
    output logic [DATA_WIDTH-1:0] pc_o,

    // [CSR]
    input wire [1:0] privilege_mode_i,
    output logic [1:0] privilege_mode_o,
    input wire if_page_fault_en_i,
    input wire if_page_fault_en_o
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            inst_o <= 0;
            pc_o <= 0;
            predict_o <= 0;
            privilege_mode_o <= 2'b11;
            clear_cache_o <= 0;
            if_page_fault_en_o <= 0;
        end else if (stall_i) begin
            // Do nothing   
        end else if (bubble_i) begin
            inst_o <= 0;
            pc_o <= 0;
            predict_o <= 0;
            privilege_mode_o <= privilege_mode_i;
            clear_cache_o <= 0;
            if_page_fault_en_o <= 0;
        end else begin
            inst_o <= inst_i;
            pc_o <= pc_i;
            predict_o <= predict_i;
            privilege_mode_o <= privilege_mode_i;
            clear_cache_o <= clear_cache_i;
            if_page_fault_en_o <= if_page_fault_en_i;
        end
    end
endmodule
