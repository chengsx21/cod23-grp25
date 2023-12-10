module mmu #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter PPN_WIDTH = 22
    // only for sv32 page
) (
    input wire clk_i,
    input wire rst_i,

    input wire [1:0] previlidge_i,
    input wire page_en_i,                // from satp[31], pipline reg
    input wire [PPN_WIDTH-1:0] ppn_i,       // from satp[21:0]

    input wire new_cycle_i,
    input wire [ADDR_WIDTH-1:0] vir_addr_i,
    output logic [ADDR_WIDTH-1:0] phy_addr_o,
    output logic phy_ready_o,
    output logic mmu_busy_o,

    output logic page_fault_en_o,

    // Wishbone Interface Signals
    output logic wb_cyc_o,
    output logic wb_stb_o,
    input wire wb_ack_i,
    output logic [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output logic [DATA_WIDTH/8-1:0] wb_sel_o,
    output logic wb_we_o
);

    typedef enum logic [3:0] { 
        PT_READ_1,
        PT_READ_2,
        DONE,
        PAGE_FAULT
    } mmu_state_t;

    mmu_state_t mmu_cstate;
    mmu_state_t mmu_nstate;

    logic [DATA_WIDTH-1:0] pte_reg;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mmu_cstate <= PT_READ_1;
            pte_reg <= 32'hFFFF_FFFF;
        end
        else begin
            mmu_cstate <= mmu_nstate;
            if(wb_ack_i) begin
                pte_reg <= wb_dat_i;
            end
        end
    end

    always_comb begin
        mmu_nstate = PT_READ_1;
        case (mmu_cstate)
            PT_READ_1: begin
                if (wb_ack_i) begin
                    if (((~wb_dat_i[0]) | ((~wb_dat_i[1])&(wb_dat_i[2]))) | (~wb_dat_i[4])) begin
                        // (V == 0)||(R == 0 && W == 1)||(U == 0)
                        mmu_nstate = PAGE_FAULT;
                    end
                    else begin
                        mmu_nstate = PT_READ_2;                        
                    end
                end
                else begin
                    mmu_nstate = PT_READ_1;
                end
            end 
            PT_READ_2: begin
                if (wb_ack_i) begin
                    if (((~wb_dat_i[0]) | ((~wb_dat_i[1])&(wb_dat_i[2]))) | (~wb_dat_i[4])) begin
                        // (V == 0)||(R == 0 && W == 1)||(U == 0)
                        mmu_nstate = PAGE_FAULT;
                    end
                    else begin
                        mmu_nstate = DONE;                      
                    end
                end
                else begin
                    mmu_nstate = PT_READ_2;
                end
            end
            DONE: begin
                if (new_cycle_i) begin
                    mmu_nstate = PT_READ_1;
                end
                else begin
                    mmu_nstate = DONE;
                end
            end
            PAGE_FAULT: begin
                if (new_cycle_i) begin
                    mmu_nstate = PT_READ_1;
                end
                else begin
                    mmu_nstate = PAGE_FAULT;
                end                
            end
            default: 
        endcase
    end

    always_comb begin
        wb_cyc_o = page_en_i && previlidge_i == 2'b00 && (~wb_ack_i) && (mmu_cstate == READ_1 || mmu_cstate == READ_2);
        wb_stb_o = wb_cyc_o;
        wb_dat_o = {DATA_WIDTH{1'b0}};
        wb_sel_o = 4'b1111;
        wb_we_o = 1'b0;
        wb_adr_o = {DATA_WIDTH{1'b0}}; //default

        page_fault_en_o = mmu_cstate == PAGE_FAULT;
        phy_ready_o = mmu_cstate == DONE || mmu_cstate == PAGE_FAULT;
        phy_addr_o = mmu_cstate == DONE ? {pte_reg[29:10], vir_addr_i[11:0]} : {DATA_WIDTH{1'b0}};
        mmu_busy_o = mmu_cstate == READ_1 || mmu_cstate == READ_2;

        case (mmu_cstate)
            // only for sv32 page
            PT_READ_1: begin                
                wb_adr_o = {ppn_i[19:0],vir_addr_i[31:22],2'b00};
            end 
            PT_READ_2: begin
                wb_adr_o = {pte_reg[29:10],vir_addr_i[21:12],2'b00};
            end
            default: begin
                wb_adr_o = {DATA_WIDTH{1'b0}};
            end
        endcase
    end
    
endmodule