module id_csr_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter PPN_WIDTH = 22
) (
    input wire clk_i,
    input wire rst_i,

    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire [ADDR_WIDTH-1:0] mem_pc_i,
    input wire [1:0] privilege_mode_i,

    input wire [1:0] csr_op_i, // 0 For Write, 1 For Set, 2 For Clear
    input wire [11:0] csr_raddr_i,
    input wire [DATA_WIDTH-1:0] rs1_rdata_i,

    input wire csr_we_i,
    input wire [11:0] csr_waddr_i,
    input wire [DATA_WIDTH-1:0] csr_wdata_i,

    input wire timer_interrupt_i,

    input wire mret_en_i,
    input wire ecall_ebreak_en_i,
    input wire if_page_fault_en_i,
    input wire mem_load_fault_en_i,
    input wire mem_store_fault_en_i,
    input wire exception_type_i,
    input wire [DATA_WIDTH-1:0] exception_code_i,

    input wire if_mmu_ready_i,
    input wire mem_mmu_ready_i,

    output logic interrupt_en_o,
    output logic [ADDR_WIDTH-1:0] interrupt_pc_o,

    output logic exception_en_o,
    output logic [ADDR_WIDTH-1:0] exception_pc_o,
    output logic [DATA_WIDTH-1:0] csr_rdata_o,
    output logic [DATA_WIDTH-1:0] csr_wdata_o,

    output logic paging_en_o,
    output logic [PPN_WIDTH-1:0] ppn_o
    );

    reg [ADDR_WIDTH-1:0] mtvec;
    reg [DATA_WIDTH-1:0] mscratch;
    reg [ADDR_WIDTH-1:0] mepc;
    reg [DATA_WIDTH-1:0] mcause;
    reg [DATA_WIDTH-1:0] mstatus;
    reg [DATA_WIDTH-1:0] mie;
    reg [DATA_WIDTH-1:0] mip;
    reg [DATA_WIDTH-1:0] satp;

    assign paging_en_o = satp[31];
    assign ppn_o = satp[21:0];

    assign exception_en_o = (ecall_ebreak_en_i | mret_en_i | if_page_fault_en_i);

    always_comb begin
        if (ecall_ebreak_en_i) begin
            exception_pc_o = mtvec;
        end
        else if (mret_en_i) begin
            exception_pc_o = mepc;
        end
        else if (mem_load_fault_en_i) begin
            exception_pc_o = mtvec;
        end
        else if (mem_store_fault_en_i) begin
            exception_pc_o = mtvec;
        end
        else if (if_page_fault_en_i) begin
            exception_pc_o = mtvec;
        end
        else begin
            exception_pc_o = {ADDR_WIDTH{1'b0}};
        end
    end

    assign mip = (timer_interrupt_i? 32'h0000_0080: 32'h0000_0000);

    always_comb begin
        interrupt_en_o = mie[7] & mip[7] & (privilege_mode_i != 2'b11);
        interrupt_pc_o = mtvec;
    end

    logic [DATA_WIDTH-1:0] csr_rdata;
    assign csr_rdata_o = csr_rdata;

    always_comb begin
        case (csr_raddr_i)
            12'h305: csr_rdata = mtvec;
            12'h340: csr_rdata = mscratch;
            12'h341: csr_rdata = mepc;
            12'h342: csr_rdata = mcause;
            12'h300: csr_rdata = mstatus;
            12'h304: csr_rdata = mie;
            12'h344: csr_rdata = mip;
            12'h180: csr_rdata = satp;
            default: csr_rdata = {DATA_WIDTH{1'b0}};
        endcase
    end

    logic [DATA_WIDTH-1:0] csr_wdata;
    assign csr_wdata_o = csr_wdata;

    always_comb begin
        case (csr_op_i) 
            2'b00: csr_wdata = rs1_rdata_i;
            2'b01: csr_wdata = rs1_rdata_i | csr_rdata;
            2'b10: csr_wdata = ~rs1_rdata_i & csr_rdata;
            default: csr_wdata = {DATA_WIDTH{1'b0}};
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mtvec <= {ADDR_WIDTH{1'b0}};
            mscratch <= {DATA_WIDTH{1'b0}};
            mepc <= {ADDR_WIDTH{1'b0}};
            mcause <= {DATA_WIDTH{1'b0}};
            mstatus <= {DATA_WIDTH{1'b0}};
            mie <= {DATA_WIDTH{1'b0}};
            satp <= {DATA_WIDTH{1'b0}};
        end
        else if (~if_mmu_ready_i || ~mem_mmu_ready_i) begin
            // block csr wirte back
        end
        else if (timer_interrupt_i & privilege_mode_i != 2'b11) begin
            mstatus <= {mstatus[31:13], privilege_mode_i, mstatus[10:0]};
            mcause <= 32'h8000_0007;
            mepc <= pc_i + 4;
        end
        else if (csr_we_i) begin
            case (csr_waddr_i)
                12'h305: mtvec <= csr_wdata_i;
                12'h340: mscratch <= csr_wdata_i;
                12'h341: mepc <= csr_wdata_i;
                12'h342: mcause <= csr_wdata_i;
                12'h300: mstatus <= csr_wdata_i;
                12'h304: mie <= csr_wdata_i;
                12'h180: satp <= csr_wdata_i;
            endcase
        end
        else if (ecall_ebreak_en_i) begin
            mstatus <= {mstatus[31:13], privilege_mode_i, mstatus[10:0]};
            mcause <= {exception_type_i, exception_code_i[DATA_WIDTH-2:0]};
            mepc <= pc_i;
        end
        else if (mem_load_fault_en_i) begin
            mstatus <= {mstatus[31:13], 2'b00, mstatus[10:0]};
            mcause <= 32'hD;
            mepc <= mem_pc_i;
        end
        else if (mem_store_fault_en_i) begin
            mstatus <= {mstatus[31:13], 2'b00, mstatus[10:0]};
            mcause <= 32'hF;
            mepc <= mem_pc_i;
        end
        else if (if_page_fault_en_i) begin
            mstatus <= {mstatus[31:13], privilege_mode_i, mstatus[10:0]};
            mcause <= {exception_type_i, exception_code_i[DATA_WIDTH-2:0]};
            mepc <= pc_i;
        end
    end
endmodule
