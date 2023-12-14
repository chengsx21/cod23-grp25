module mmu #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter PPN_WIDTH = 22    // only for sv32 page
) (
    input wire clk_i,
    input wire rst_i,

    input wire type_i, // 0 for if, 1 for mem
    input wire mem_type_i,  // 0 for store, 1 for load
    input wire mem_en_i,

    input wire [1:0] privilidge_i,
    input wire page_en_i,                // from satp[31], pipline reg
    input wire [PPN_WIDTH-1:0] ppn_i,       // from satp[21:0]

    input wire new_cycle_i,
    input wire [ADDR_WIDTH-1:0] vir_addr_i,
    output logic [ADDR_WIDTH-1:0] phy_addr_o,
    output logic phy_ready_o,
    output logic mmu_busy_o,

    output logic page_fault_en_o,
    output logic inst_page_fault_o,
    output logic store_page_fault_o,
    output logic load_page_fault_o,

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

    logic clock_adr_comb;

    logic is_page_fault;
    logic instruction_page_fault;
    logic load_page_fault;
    logic store_page_fault;
    logic invalid_page;
    logic invalid_privilege_mode;

    reg [15:0][19:0] vir_page_number_table;
    reg [15:0][19:0] phy_page_number_table;
    reg [15:0] valid_table;
    reg first_done;
    wire tlb_hit;

    assign tlb_hit = valid_table[vir_addr_i[15:12]] && (vir_page_number_table[vir_addr_i[15:12]] == vir_addr_i[31:12]);

    always_comb begin
        // UXWRV 43210
        invalid_page = (~wb_dat_i[0]) || ((~wb_dat_i[1]) && (wb_dat_i[2]));
        invalid_privilege_mode = ((~wb_dat_i[4]) && (mmu_cstate == PT_READ_2));
        
        instruction_page_fault = wb_ack_i && (type_i == 1'b0) && (invalid_page || invalid_privilege_mode || ((~wb_dat_i[3]) && (mmu_cstate == PT_READ_2)));
        store_page_fault = wb_ack_i && (type_i == 1'b1) && (mem_type_i == 1'b1) && (invalid_page || invalid_privilege_mode || ((~wb_dat_i[2]) && (mmu_cstate == PT_READ_2)));
        load_page_fault = wb_ack_i && (type_i == 1'b1) && (mem_type_i == 1'b0) && (invalid_page || invalid_privilege_mode || ((~wb_dat_i[1]) && (mmu_cstate == PT_READ_2)));

        is_page_fault = instruction_page_fault || store_page_fault || load_page_fault;
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mmu_cstate <= PT_READ_1;
            pte_reg <= 32'hFFFF_FFFF;
            page_fault_en_o <= 0;
            inst_page_fault_o <= 0;
            store_page_fault_o <= 0;
            load_page_fault_o <= 0;
        end
        else begin
            mmu_cstate <= mmu_nstate;
            if(wb_ack_i) begin
                pte_reg <= wb_dat_i;
            end
            if (mmu_nstate == PT_READ_1) begin
                page_fault_en_o <= 0;
                inst_page_fault_o <= 0;
                store_page_fault_o <= 0;
                load_page_fault_o <= 0;
            end
            else if (mmu_nstate == PAGE_FAULT) begin
                page_fault_en_o <= 1;
                if (instruction_page_fault) begin
                    inst_page_fault_o <= 1'b1;
                end                    
                else if (load_page_fault) begin
                    load_page_fault_o <= 1'b1;
                end
                else if (store_page_fault) begin
                    store_page_fault_o <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            first_done <= 1'b0;
        end
        else begin
            if (mmu_cstate == PT_READ_2 && mmu_nstate == DONE) begin
                first_done <= 1'b1;
            end
            else begin
                first_done <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                vir_page_number_table[i] <= 20'b0;
                phy_page_number_table[i] <= 20'b0;
                valid_table[i] <= 1'b0;
            end
        end
        else if (first_done && ((~type_i) || (~clock_adr_comb && mem_en_i)) && privilidge_i == 2'b00 && page_en_i) begin
            vir_page_number_table[vir_addr_i[15:12]] <= vir_addr_i[31:12];
            phy_page_number_table[vir_addr_i[15:12]] <= phy_addr_o[31:12];
            valid_table[vir_addr_i[15:12]] <= 1'b1;
        end
    end

    always_comb begin
        mmu_nstate = PT_READ_1;
        case (mmu_cstate)
            PT_READ_1: begin
                if (wb_ack_i) begin
                    if (is_page_fault) begin
                        // (V == 0)||(R == 0 && W == 1)
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
                    if (is_page_fault) begin
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
        endcase
    end

    

    always_comb begin
        clock_adr_comb = vir_addr_i == 32'h0200bff8 || vir_addr_i == 32'h0200bffc || vir_addr_i == 32'h02004000 || vir_addr_i == 32'h02004004;
        wb_cyc_o = page_en_i && privilidge_i == 2'b00 && ((~type_i) || (~clock_adr_comb && mem_en_i)) && (~wb_ack_i) && (mmu_cstate == PT_READ_1 || mmu_cstate == PT_READ_2) && ~tlb_hit;
        wb_stb_o = wb_cyc_o;
        wb_dat_o = {DATA_WIDTH{1'b0}};
        wb_sel_o = 4'b1111;
        wb_we_o = 1'b0;
        wb_adr_o = {DATA_WIDTH{1'b0}}; //default

        phy_ready_o = mmu_cstate == DONE || mmu_cstate == PAGE_FAULT || (type_i && (clock_adr_comb || (~mem_en_i))) || privilidge_i == 2'b11 || ~page_en_i || tlb_hit;
        phy_addr_o = tlb_hit ? {phy_page_number_table[vir_addr_i[15:12]], vir_addr_i[11:0]} : (mmu_cstate == DONE ? {pte_reg[29:10], vir_addr_i[11:0]} : {DATA_WIDTH{1'b0}});
        mmu_busy_o = (mmu_cstate == PT_READ_1 || mmu_cstate == PT_READ_2) && ((~type_i) || (~clock_adr_comb && mem_en_i)) && privilidge_i == 2'b00 && page_en_i && ~tlb_hit;

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