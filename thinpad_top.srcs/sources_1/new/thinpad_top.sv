`default_nettype none

module thinpad_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
	parameter PPN_WIDTH = 22
) (
    input wire clk_50M,     // 50MHz clock input
    input wire clk_11M0592, // 11.0592MHz clock input

    input wire push_btn,  // BTN5 debounced, pressed as signal 1
    input wire reset_btn, // BTN6 debounced, pressed as signal 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4, pressed as signal 1
    input  wire [ADDR_WIDTH-1:0] dip_sw,     // 32bit DIP switch, set on "ON" as signal 1
    output wire [15:0] leds,       // 16bit LEDs, light on as signal 1
    output wire [ 7:0] dpy0,       // 8bit 7-seg-low  display, with dot, light on as signal 1
    output wire [ 7:0] dpy1,       // 8bit 7-seg-high display, with dot, light on as signal 1

    // CPLD uart controller
    output wire uart_rdn,        // read  uart signal, low level effectively
    output wire uart_wrn,        // write uart signal, low level effectively
    input  wire uart_dataready,  // uart data ready signal
    input  wire uart_tbre,       // uart transmit signal
    input  wire uart_tsre,       // uart transmit ready signal

    // BaseRAM signal
    inout wire [ADDR_WIDTH-1:0] base_ram_data,  // BaseRAM data, low 8 bits shared with uart controller
    output wire [19:0] base_ram_addr,  // BaseRAM address
    output wire [3:0] base_ram_be_n,  // BaseRAM byte enable signal, low level effectively
    output wire base_ram_ce_n,  // BaseRAM chip enable signal, low level effectively
    output wire base_ram_oe_n,  // BaseRAM output enable signal, low level effectively
    output wire base_ram_we_n,  // BaseRAM write enable signal, low level effectively

    // ExtRAM signal
    inout wire [ADDR_WIDTH-1:0] ext_ram_data,  // ExtRAM data
    output wire [19:0] ext_ram_addr,  // ExtRAM address
    output wire [3:0] ext_ram_be_n,  // ExtRAM byte enable signal, low level effectively
    output wire ext_ram_ce_n,  // ExtRAM chip enable signal, low level effectively
    output wire ext_ram_oe_n,  // ExtRAM output enable signal, low level effectively
    output wire ext_ram_we_n,  // ExtRAM write enable signal, low level effectively

    // UART signal
    output wire txd,  // Uart output signal
    input  wire rxd,  // Uart input signal

    // Flash Memory signal, follow JS28F640 brochure
    output wire [22:0] flash_a,  // Flash address, a0 effective in 8bit mode, ineffective in 16bit mode
    inout wire [15:0] flash_d,  // Flash data
    output wire flash_rp_n,  // Flash reset, low level effectively
    output wire flash_vpen,  // Flash write protect, low level effectively, cannot write or erase
    output wire flash_ce_n,  // Flash chip enable, low level effectively
    output wire flash_oe_n,  // Flash output enable, low level effectively
    output wire flash_we_n,  // Flash write enable, low level effectively
    output wire flash_byte_n, // Flash 8bit mode, low level effectively, set as 1 for 16bit mode

    // USB controller signal, follow SL811 brochure
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB data bus shared with Network controller signal `dm9k_sd[7:0]`
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // Network controller signal, follow DM9000A brochure
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // Image output signal
    output wire [2:0] video_red,    // Red pixel, 3 bits
    output wire [2:0] video_green,  // Green pixel, 3 bits
    output wire [1:0] video_blue,   // Blue pixel, 2 bits
    output wire       video_hsync,  // Horizontal sync signal
    output wire       video_vsync,  // Vertical sync signal
    output wire       video_clk,    // Pixel clock output
    output wire       video_de      // Horizontal data enable signal, used to indicate the valid data
);

	/* =========== Demo code begin =========== */
	
	// PLL frequency divider
	logic locked, clk50M;
	pll_example clock_gen (
		// Clock in ports
		.clk_in1(clk_50M),  // Outside clock input
		// Clock out ports
		.clk_out1(clk50M),  // Frequency set in IP config page
		// Status and control signals
		.reset(reset_btn),  // PLL reset
		.locked(locked)  // PLL lock signal, 1 when stable
	);
	assign video_clk = clk50M;

	logic [18:0] bram_addr_a;
    logic [7:0] bram_data_in_a;
	logic [7:0] bram_data_out_a;
	logic bram_en_a;
    logic bram_we_a;

	logic vga_bram_en;
    logic [18:0] vga_bram_addr;
    logic [7:0] vga_bram_data;

	block_mem block_mem_1 (
		.clka(sys_clk),
		.ena(bram_en_a),
		.wea(bram_we_a),
		.addra(bram_addr_a),
		.dina(bram_data_in_a),
		.douta(bram_data_out_a),

		.clkb(sys_clk),
		.enb(vga_bram_en),
		.web(0),
		.addrb(vga_bram_addr),
		.dinb(8'b0),
		.doutb(vga_bram_data)
	);
	logic reset_of_clk50M;
	// Async reset, sync free, transform locked to reset_of_clk50M
	always_ff @(posedge clk50M or negedge locked) begin
		if (~locked) reset_of_clk50M <= 1'b1;
		else reset_of_clk50M <= 1'b0;
	end

	assign uart_rdn = 1'b1;
	assign uart_wrn = 1'b1;

	logic sys_clk;
	logic sys_rst;

	assign sys_clk = clk50M;
	assign sys_rst = reset_of_clk50M;

	//* =========== Demo code end =========== *//

	//* ================= IF ================= *//

	logic pc_stall;
	logic [ADDR_WIDTH-1:0] if_pc;
	logic [ADDR_WIDTH-1:0] if_pc_next;

	logic [1:0] if_privilege_mode;
	logic [1:0] if_privilege_mode_nxt;

	if_pc_reg if_pc_reg (
		.clk_i(sys_clk),
		.rst_i(sys_rst),
		.pc_stall_i(pc_stall),
		.pc_next_i(if_pc_next),
		.privilege_mode_i(if_privilege_mode_nxt),

		.pc_current_o(if_pc),
		.privilege_mode_o(if_privilege_mode)
    );

	logic [DATA_WIDTH-1:0] exe_alu_y;
	logic pc_sel;
	logic [ADDR_WIDTH-1:0] if_jp_pc;
	logic [ADDR_WIDTH-1:0] exe_jp_pc;

	logic [ADDR_WIDTH-1:0] csr_exception_pc;

	if_pc_mux if_pc_mux (
		.pc_if(if_jp_pc),
		.pc_exe(exe_jp_pc),
		.pc_exception(csr_exception_pc),
		.exception_en_i(csr_exception_en),
		.pc_sel_i(pc_sel),
		.pc_next_o(if_pc_next)
    );

	logic csr_exception_en;
	logic [1:0] csr_exception_privilege_mode;

	if_priv_mode_mux if_priv_mode_mux (
		.exception_en_i(csr_exception_en),
		.if_privilege_mode_i(if_privilege_mode),
		.exception_privilege_mode_i(csr_exception_privilege_mode),
		.privilege_mode_o(if_privilege_mode_nxt)
	);

	logic [DATA_WIDTH-1:0] if_mem_inst;
	logic [DATA_WIDTH-1:0] if_cache_inst;
	logic [DATA_WIDTH-1:0] if_inst;
	logic im_ready;
	logic if_cache_en;
	logic if_cache_we;
	logic if_clear_cache;

	logic paging_en;
	logic if_mmu_ready;
	logic [ADDR_WIDTH-1:0] if_phy_addr;
	logic if_page_fault_en;
	logic if_mmu_next_fetch;

	logic wb0_master_cyc_o;
	logic wb0_master_stb_o;
	logic wb0_master_ack_i;
	logic [ADDR_WIDTH-1:0] wb0_master_adr_o;
	logic [DATA_WIDTH-1:0] wb0_master_dat_o;
	logic [DATA_WIDTH-1:0] wb0_master_dat_i;
	logic [DATA_WIDTH/8-1:0] wb0_master_sel_o;
	logic wb0_master_we_o;

	logic if_inst_misalign_en;

	if_im_master if_im_master (
		.clk_i(sys_clk),
		.rst_i(sys_rst),
		.pc_i(if_pc),
		.pc_sel_i(pc_sel),
		.pc_exception_i(csr_exception_en),
		.cache_en_i(if_cache_en),
		.inst_o(if_mem_inst),
		.im_ready_o(im_ready),
		.cache_we_o(if_cache_we),

		.inst_misalign_en_o(if_inst_misalign_en),

		.privilidge_i(if_privilege_mode),
		.paging_en_i(paging_en),
		.mmu_ready_i(if_mmu_ready),
		.phy_addr_i(if_phy_addr),
		.page_fault_en_i(if_page_fault_en),
		.mmu_next_fetch_o(if_mmu_next_fetch),

		.wb_cyc_o(wb0_master_cyc_o),
		.wb_stb_o(wb0_master_stb_o),
		.wb_ack_i(wb0_master_ack_i),
		.wb_adr_o(wb0_master_adr_o),
		.wb_dat_o(wb0_master_dat_o),
		.wb_dat_i(wb0_master_dat_i),
		.wb_sel_o(wb0_master_sel_o),
		.wb_we_o(wb0_master_we_o)
	);

	logic [PPN_WIDTH-1:0] ppn;

	logic if_mmu_busy;

	logic wb0_mmu_cyc_o;
	logic wb0_mmu_stb_o;
	logic wb0_mmu_ack_i;
	logic [ADDR_WIDTH-1:0] wb0_mmu_adr_o;
	logic [DATA_WIDTH-1:0] wb0_mmu_dat_o;
	logic [DATA_WIDTH-1:0] wb0_mmu_dat_i;
	logic [DATA_WIDTH/8-1:0] wb0_mmu_sel_o;
	logic wb0_mmu_we_o;

	mmu if_mmu (
		.clk_i(sys_clk),
		.rst_i(sys_rst),

		.type_i(1'b0),
		.mem_en_i(1'b0),
		.mem_type_i(1'b0),

		.privilidge_i(if_privilege_mode),
		.page_en_i(paging_en),
		.ppn_i(ppn),

		.new_cycle_i(if_mmu_next_fetch),
		.vir_addr_i(if_pc),
		.phy_addr_o(if_phy_addr),
		.phy_ready_o(if_mmu_ready),
		.mmu_busy_o(if_mmu_busy),

		.page_fault_en_o(if_page_fault_en),
		.inst_page_fault_o(),
		.store_page_fault_o(),
		.load_page_fault_o(),

		.wb_cyc_o(wb0_mmu_cyc_o),
		.wb_stb_o(wb0_mmu_stb_o),
		.wb_ack_i(wb0_mmu_ack_i),
		.wb_adr_o(wb0_mmu_adr_o),
		.wb_dat_o(wb0_mmu_dat_o),
		.wb_dat_i(wb0_mmu_dat_i),
		.wb_sel_o(wb0_mmu_sel_o),
		.wb_we_o(wb0_mmu_we_o)
	);

	logic wb0_cyc_o;
	logic wb0_stb_o;
	logic wb0_ack_i;
	logic [ADDR_WIDTH-1:0] wb0_adr_o;
	logic [DATA_WIDTH-1:0] wb0_dat_o;
	logic [DATA_WIDTH-1:0] wb0_dat_i;
	logic [DATA_WIDTH/8-1:0] wb0_sel_o;
	logic wb0_we_o;

	mmu_master_mux if_mmu_master_mux (
		.sel_i(if_mmu_busy),

		.mmu_wb_cyc_i(wb0_mmu_cyc_o),
		.mmu_wb_stb_i(wb0_mmu_stb_o),
		.mmu_wb_ack_o(wb0_mmu_ack_i),
		.mmu_wb_adr_i(wb0_mmu_adr_o),
		.mmu_wb_dat_i(wb0_mmu_dat_o),
		.mmu_wb_dat_o(wb0_mmu_dat_i),
		.mmu_wb_sel_i(wb0_mmu_sel_o),
		.mmu_wb_we_i(wb0_mmu_we_o),

		.master_wb_cyc_i(wb0_master_cyc_o),
		.master_wb_stb_i(wb0_master_stb_o),
		.master_wb_ack_o(wb0_master_ack_i),
		.master_wb_adr_i(wb0_master_adr_o),
		.master_wb_dat_i(wb0_master_dat_o),
		.master_wb_dat_o(wb0_master_dat_i),
		.master_wb_sel_i(wb0_master_sel_o),
		.master_wb_we_i(wb0_master_we_o),

		.wb_cyc_o(wb0_cyc_o),
		.wb_stb_o(wb0_stb_o),
		.wb_ack_i(wb0_ack_i),
		.wb_adr_o(wb0_adr_o),
		.wb_dat_o(wb0_dat_o),
		.wb_dat_i(wb0_dat_i),
		.wb_sel_o(wb0_sel_o),
		.wb_we_o(wb0_we_o)
	);

	//* =============== IF-ID =============== *//

	logic if_id_stall;
	logic if_id_bubble;

	logic if_predict;
	logic id_predict;
	logic id_clear_cache;

	logic [ADDR_WIDTH-1:0] id_pc;
	logic [DATA_WIDTH-1:0] id_inst;

	logic [1:0] id_privilege_mode;
	logic id_page_fault_en;

	logic id_inst_misalign_en;

	if_id_regs if_id_regs (
		.clk_i(sys_clk),
		.rst_i(sys_rst),
		.stall_i(if_id_stall),
		.bubble_i(if_id_bubble),

		// [ID] ~ [EXE]
		.inst_i(if_inst),
		.inst_o(id_inst),
		.predict_i(if_predict),
		.predict_o(id_predict),
		.clear_cache_i(if_clear_cache),
		.clear_cache_o(id_clear_cache),

		// [EXE] ~ [MEM]
		.pc_i(if_pc),
		.pc_o(id_pc),

		// [CSR]
		.privilege_mode_i(if_privilege_mode),
	    .privilege_mode_o(id_privilege_mode),
		.inst_misalign_en_i(if_inst_misalign_en),
		.inst_misalign_en_o(id_inst_misalign_en),
		.if_page_fault_en_i(if_page_fault_en),
		.if_page_fault_en_o(id_page_fault_en)
    );

	//* ================= ID ================= *//

	logic [4:0] id_rs1;
	logic [4:0] id_rs2;

	logic [2:0] id_br_op;
	logic [1:0] id_alu_a_mux_sel;
	logic [1:0] id_alu_b_mux_sel;
	logic [3:0] id_alu_op;

	logic id_dm_en;
	logic id_dm_we;
	logic [2:0] id_dm_dat_width;
	logic [1:0] id_writeback_mux_sel;

	logic [4:0] id_rd;
	logic id_reg_we;

    logic id_csr_we;
    logic [1:0] id_csr_op;
    logic [11:0] id_csr_addr;

	logic id_mret_en;
	logic id_ecall_ebreak_en;
	logic id_inst_illegal_en;
	logic id_exception_type;
	logic [DATA_WIDTH-1:0] id_exception_code;
	logic [1:0] id_exception_privilege_mode;
    logic [1:0] id_instruction_mode;

 	id_decoder id_decoder (
		.inst_i(id_inst),
		.if_page_fault_en_i(id_page_fault_en),

		// [ID] ~ [EXE]
		.rs1_o(id_rs1),
		.rs2_o(id_rs2),

		.br_op_o(id_br_op),
		.alu_a_mux_sel_o(id_alu_a_mux_sel),
		.alu_b_mux_sel_o(id_alu_b_mux_sel),
		.alu_op_o(id_alu_op),

		// [EXE] ~ [MEM]
		.dm_en_o(id_dm_en),
		.dm_we_o(id_dm_we),
		.dm_dat_width_o(id_dm_dat_width),
		.writeback_mux_sel_o(id_writeback_mux_sel),

		// [MEM] ~ [WRITEBACK]
		.rd_o(id_rd),
		.reg_we_o(id_reg_we),

		// [CSR]
		.csr_we_o(id_csr_we),
		.csr_op_o(id_csr_op),
		.csr_addr_o(id_csr_addr),

		.mret_en_o(id_mret_en),
		.ecall_ebreak_en_o(id_ecall_ebreak_en),
		.inst_illegal_en_o(id_inst_illegal_en),
		.exception_type_o(id_exception_type),
		.exception_code_o(id_exception_code),
		.exception_privilege_mode_o(id_exception_privilege_mode),
		.instruction_mode_o(id_instruction_mode)
    );

	logic [DATA_WIDTH-1:0] id_imm;

	id_imm_gen id_imm_gen (
		.inst_i(id_inst),
		.imm_o(id_imm)
	);

	logic writeback_reg_we;
	logic [4:0] writeback_rd;
	logic [DATA_WIDTH-1:0] writeback_reg_dat;
	logic [DATA_WIDTH-1:0] id_rs1_dat;
	logic [DATA_WIDTH-1:0] id_rs2_dat;

	id_reg_file id_reg_file (
		.clk_i(sys_clk),
		.rst_i(sys_rst),

		.we_i(writeback_reg_we),
		.waddr_i(writeback_rd),
		.wdata_i(writeback_reg_dat),
		.raddr_a_i(id_rs1),
		.rdata_a_o(id_rs1_dat),
		.raddr_b_i(id_rs2),
		.rdata_b_o(id_rs2_dat)
	);

	logic [DATA_WIDTH-1:0] forward_rs1_dat;
	logic forward_rs1_dat_sel;
	logic [DATA_WIDTH-1:0] rs1_dat;

	id_rdata_a_mux id_rdata_a_mux (
		.rdata_a_i(id_rs1_dat),
		.forward_rdata_a_i(forward_rs1_dat),
		.forward_rdata_a_sel_i(forward_rs1_dat_sel),
		.rdata_a_o(rs1_dat)
	);

	logic [DATA_WIDTH-1:0] forward_rs2_dat;
	logic forward_rs2_dat_sel;
	logic [DATA_WIDTH-1:0] rs2_dat;

	id_rdata_b_mux id_rdata_b_mux (
		.rdata_b_i(id_rs2_dat),
		.forward_rdata_b_i(forward_rs2_dat),
		.forward_rdata_b_sel_i(forward_rs2_dat_sel),
		.rdata_b_o(rs2_dat)
	);

	logic writeback_csr_we;
	logic [11:0] writeback_csr_waddr;
	logic [DATA_WIDTH-1:0] writeback_csr_wdata;
	logic [DATA_WIDTH-1:0] id_csr_rdata;
	logic [DATA_WIDTH-1:0] id_csr_wdata;

	logic mem_page_fault_en;
	logic mem_load_fault_en;
	logic mem_store_fault_en;

	logic mem_mmu_ready;

	logic id_exception_en;
	logic [ADDR_WIDTH-1:0] id_exception_pc;
	logic mtime_interrupt_en;
	logic [ADDR_WIDTH-1:0] mtime_interrupt_pc;

	id_csr_file id_csr_file (
		.clk_i(sys_clk),
		.rst_i(sys_rst),

		.pc_i(id_pc),
		.mem_pc_i(mem_pc),
		.privilege_mode_i(id_privilege_mode),

		.csr_op_i(id_csr_op),
		.csr_raddr_i(id_csr_addr),
		.rs1_rdata_i(rs1_dat),
		.csr_we_i(writeback_csr_we),
		.csr_waddr_i(writeback_csr_waddr),
		.csr_wdata_i(writeback_csr_wdata),

		.timer_interrupt_i(timer_interrupt),

		.mret_en_i(id_mret_en),
		.ecall_ebreak_en_i(id_ecall_ebreak_en),
		.inst_illegal_en_i(id_inst_illegal_en),
		.inst_misalign_en_i(id_inst_misalign_en),
		.load_misalign_en_i(mem_load_misalign_en),
		.store_misalign_en_i(mem_store_misalign_en),
		.if_page_fault_en_i(id_page_fault_en),
		.mem_load_fault_en_i(mem_load_fault_en),
		.mem_store_fault_en_i(mem_store_fault_en),
		.exception_type_i(id_exception_type),
		.exception_code_i(id_exception_code),

		.if_mmu_ready_i(if_mmu_ready),
		.mem_mmu_ready_i(mem_mmu_ready),

		.interrupt_en_o(mtime_interrupt_en),
		.interrupt_pc_o(mtime_interrupt_pc),

		.exception_en_o(id_exception_en),
		.exception_pc_o(id_exception_pc),

		.csr_rdata_o(id_csr_rdata),
		.csr_wdata_o(id_csr_wdata),

		.paging_en_o(paging_en),
		.ppn_o(ppn)
	);

	//* =============== ID-EXE =============== *//

	logic id_exe_stall;
	logic id_exe_bubble;

	logic [ADDR_WIDTH-1:0] exe_pc;
	logic [DATA_WIDTH-1:0] exe_inst;
	logic [DATA_WIDTH-1:0] exe_imm;
	logic [4:0] exe_rs1;
	logic [4:0] exe_rs2;

	logic [DATA_WIDTH-1:0] exe_rs1_dat;
	logic [DATA_WIDTH-1:0] exe_rs2_dat;

	logic [2:0] exe_br_op;
	logic [1:0] exe_alu_a_mux_sel;
	logic [1:0] exe_alu_b_mux_sel;
	logic [3:0] exe_alu_op;
	logic exe_predict;
	logic exe_clear_cache;

	logic exe_dm_en;
	logic exe_dm_we;
	logic [2:0] exe_dm_dat_width;
	logic [1:0] exe_writeback_mux_sel;

	logic [4:0] exe_rd;
	logic exe_reg_we;

    logic exe_csr_we;
	logic [11:0] exe_csr_waddr;
	logic [DATA_WIDTH-1:0] exe_csr_rdata;
	logic [DATA_WIDTH-1:0] exe_csr_wdata;
	logic exe_exception_en;
	logic [ADDR_WIDTH-1:0] exe_exception_pc;
	logic [1:0] exe_exception_privilege_mode;
	logic [1:0] exe_privilege_mode;
    logic [1:0] exe_instruction_mode;

	id_exe_regs id_exe_regs (
		.clk_i(sys_clk),
		.rst_i(sys_rst),
		.stall_i(id_exe_stall),
		.bubble_i(id_exe_bubble),

		// [ID] ~ [EXE]
		.inst_i(id_inst),
		.inst_o(exe_inst),
		.imm_i(id_imm),
		.imm_o(exe_imm),
		.rs1_i(id_rs1),
		.rs1_o(exe_rs1),
		.rs2_i(id_rs2),
		.rs2_o(exe_rs2),

		.rs1_dat_i(rs1_dat),
		.rs1_dat_o(exe_rs1_dat),
		.br_op_i(id_br_op),
		.br_op_o(exe_br_op),
		.alu_a_mux_sel_i(id_alu_a_mux_sel),
		.alu_a_mux_sel_o(exe_alu_a_mux_sel),
		.alu_b_mux_sel_i(id_alu_b_mux_sel),
		.alu_b_mux_sel_o(exe_alu_b_mux_sel),
		.alu_op_i(id_alu_op),
		.alu_op_o(exe_alu_op),
		.predict_i(id_predict),
		.predict_o(exe_predict),
		.clear_cache_i(id_clear_cache),
		.clear_cache_o(exe_clear_cache),

		// [EXE] ~ [MEM]
		.pc_i(id_pc),
		.pc_o(exe_pc),
		.rs2_dat_i(rs2_dat),
		.rs2_dat_o(exe_rs2_dat),
		.dm_en_i(id_dm_en),
		.dm_en_o(exe_dm_en),
		.dm_we_i(id_dm_we),
		.dm_we_o(exe_dm_we),
		.dm_dat_width_i(id_dm_dat_width),
		.dm_dat_width_o(exe_dm_dat_width),
		.writeback_mux_sel_i(id_writeback_mux_sel),
		.writeback_mux_sel_o(exe_writeback_mux_sel),

		// [MEM] ~ [WRITEBACK]
		.rd_i(id_rd),
		.rd_o(exe_rd),
		.reg_we_i(id_reg_we),
		.reg_we_o(exe_reg_we),

		// [CSR]
		.csr_we_i(id_csr_we),
		.csr_we_o(exe_csr_we),
		.csr_addr_i(id_csr_addr),
		.csr_addr_o(exe_csr_waddr),
		.csr_wdata_i(id_csr_wdata),
		.csr_wdata_o(exe_csr_wdata),
		.csr_rdata_i(id_csr_rdata),
		.csr_rdata_o(exe_csr_rdata),
		.exception_en_i(id_exception_en),
		.exception_en_o(exe_exception_en),
		.exception_pc_i(id_exception_pc),
		.exception_pc_o(exe_exception_pc),
		.privilege_mode_i(id_privilege_mode),
		.privilege_mode_o(exe_privilege_mode),
		.exception_privilege_mode_i(id_exception_privilege_mode),
		.exception_privilege_mode_o(exe_exception_privilege_mode),
		.instruction_mode_i(id_instruction_mode),
		.instruction_mode_o(exe_instruction_mode)
	);

	//* ================= EXE ================= *//

	logic exe_br_taken;
	logic exe_br_en;

	exe_b_comp exe_b_comp (
		.rs1_dat_i(exe_rs1_dat),
		.rs2_dat_i(exe_rs2_dat),
		.br_op_i(exe_br_op),
		.br_taken_o(exe_br_taken),
		.br_en_o(exe_br_en)
    );

	logic [DATA_WIDTH-1:0] exe_alu_a;

	exe_alu_a_mux exe_alu_a_mux (
		.rs1_dat_i(exe_rs1_dat),
		.pc_i(exe_pc),
		.csr_dat_i(exe_csr_rdata),
		.alu_a_sel_i(exe_alu_a_mux_sel),
		.alu_a_o(exe_alu_a)
    );

	logic [DATA_WIDTH-1:0] exe_alu_b;

	exe_alu_b_mux exe_alu_b_mux (
		.rs2_dat_i(exe_rs2_dat),
		.imm_i(exe_imm),
		.alu_b_sel_i(exe_alu_b_mux_sel),
		.alu_b_o(exe_alu_b)
    );

	exe_alu exe_alu (
		.a_i(exe_alu_a),
		.b_i(exe_alu_b),
		.op_i(exe_alu_op),
		.y_i(exe_alu_y)
    );

	//* =============== EXE-MEM =============== *//

	logic exe_mem_stall;
	logic exe_mem_bubble;

	logic [ADDR_WIDTH-1:0] mem_pc;
	logic [DATA_WIDTH-1:0] mem_alu_y;
	logic [DATA_WIDTH-1:0] mem_rs2_dat;
	logic mem_dm_en;
	logic mem_dm_we;
	logic [2:0] mem_dm_dat_width;
	logic [1:0] mem_writeback_mux_sel;

	logic [4:0] mem_rd;
	logic mem_reg_we;

    logic mem_csr_we;
	logic [11:0] mem_csr_waddr;
	logic [DATA_WIDTH-1:0] mem_csr_wdata;
	logic mem_exception_en;
	logic [ADDR_WIDTH-1:0] mem_exception_pc;
	logic [1:0] mem_exception_privilege_mode;
	logic [1:0] mem_privilege_mode;
    logic [1:0] mem_instruction_mode;

	exe_mem_regs exe_mem_regs (
		.clk_i(sys_clk),
		.rst_i(sys_rst),
		.stall_i(exe_mem_stall),
		.bubble_i(exe_mem_bubble),

		// [EXE] ~ [MEM]
		.pc_i(exe_pc),
		.pc_o(mem_pc),
		.alu_y_i(exe_alu_y),
    	.alu_y_o(mem_alu_y),
		.rs2_dat_i(exe_rs2_dat),
		.rs2_dat_o(mem_rs2_dat),
		.dm_en_i(exe_dm_en),
		.dm_en_o(mem_dm_en),
		.dm_we_i(exe_dm_we),
		.dm_we_o(mem_dm_we),
		.dm_dat_width_i(exe_dm_dat_width),
		.dm_dat_width_o(mem_dm_dat_width),
		.writeback_mux_sel_i(exe_writeback_mux_sel),
		.writeback_mux_sel_o(mem_writeback_mux_sel),

		// [MEM] ~ [WRITEBACK]
		.rd_i(exe_rd),
		.rd_o(mem_rd),
		.reg_we_i(exe_reg_we),
		.reg_we_o(mem_reg_we),

		// [CSR]
		.csr_we_i(exe_csr_we),
		.csr_we_o(mem_csr_we),
		.csr_waddr_i(exe_csr_waddr),
		.csr_waddr_o(mem_csr_waddr),
		.csr_wdata_i(exe_csr_wdata),
		.csr_wdata_o(mem_csr_wdata),
		.exception_en_i(exe_exception_en),
		.exception_en_o(mem_exception_en),
		.exception_pc_i(exe_exception_pc),
		.exception_pc_o(mem_exception_pc),
		.privilege_mode_i(exe_privilege_mode),
		.privilege_mode_o(mem_privilege_mode),
		.exception_privilege_mode_i(exe_exception_privilege_mode),
		.exception_privilege_mode_o(mem_exception_privilege_mode),
		.instruction_mode_i(exe_instruction_mode),
		.instruction_mode_o(mem_instruction_mode)
	);

	//* ================= MEM ================= *//

	logic [DATA_WIDTH-1:0] mem_dm_dat;
	logic dm_ready;

	logic [ADDR_WIDTH-1:0] mem_phy_addr;
	logic mem_mmu_next_fetch;

	logic wb1_master_cyc_o;
	logic wb1_master_stb_o;
	logic wb1_master_ack_i;
	logic [ADDR_WIDTH-1:0] wb1_master_adr_o;
	logic [DATA_WIDTH-1:0] wb1_master_dat_o;
	logic [DATA_WIDTH-1:0] wb1_master_dat_i;
	logic [DATA_WIDTH/8-1:0] wb1_master_sel_o;
	logic wb1_master_we_o;

	logic mem_load_misalign_en;
	logic mem_store_misalign_en;

	mem_dm_master mem_dm_master (
		.clk_i(sys_clk),
		.rst_i(sys_rst),
		.dm_en_i(mem_dm_en),
		.dm_we_i(mem_dm_we),
		.dm_dat_width_i(mem_dm_dat_width),
		.dm_adr_i(mem_alu_y),
		.dm_dat_i(mem_rs2_dat),
		.dm_dat_o(mem_dm_dat),
		.dm_ready_o(dm_ready),

		.load_misalign_en_o(mem_load_misalign_en),
		.store_misalign_en_o(mem_store_misalign_en),

		.mt_mtime_i(mt_mtime),
		.mt_mtimecmp_i(mt_mtimecmp),
		.mt_mtime_we_o(mt_mtime_we),
		.mt_mtimecmp_we_o(mt_mtimecmp_we),
		.mt_high_we_o(mt_high_we),
		.mt_mtime_wdata_o(mt_mtime_wdata),

		.privilidge_i(mem_privilege_mode),
		.page_en_i(paging_en),
		.mmu_ready_i(mem_mmu_ready),
		.phy_addr_i(mem_phy_addr),
		.page_fault_en_i(mem_page_fault_en),
		.mmu_next_fetch_o(mem_mmu_next_fetch),

		.wb_cyc_o(wb1_master_cyc_o),
		.wb_stb_o(wb1_master_stb_o),
		.wb_ack_i(wb1_master_ack_i),
		.wb_adr_o(wb1_master_adr_o),
		.wb_dat_o(wb1_master_dat_o),
		.wb_dat_i(wb1_master_dat_i),
		.wb_sel_o(wb1_master_sel_o),
		.wb_we_o(wb1_master_we_o)
    );

	logic mem_mmu_busy;

	logic wb1_mmu_cyc_o;
	logic wb1_mmu_stb_o;
	logic wb1_mmu_ack_i;
	logic [ADDR_WIDTH-1:0] wb1_mmu_adr_o;
	logic [DATA_WIDTH-1:0] wb1_mmu_dat_o;
	logic [DATA_WIDTH-1:0] wb1_mmu_dat_i;
	logic [DATA_WIDTH/8-1:0] wb1_mmu_sel_o;
	logic wb1_mmu_we_o;

	mmu mem_mmu (
		.clk_i(sys_clk),
		.rst_i(sys_rst),

		.type_i(1'b1),
		.mem_type_i(mem_dm_we),
		.mem_en_i(mem_dm_en),

		.privilidge_i(mem_privilege_mode),
		.page_en_i(paging_en),
		.ppn_i(ppn),

		.new_cycle_i(mem_mmu_next_fetch),
		.vir_addr_i(mem_alu_y),
		.phy_addr_o(mem_phy_addr),
		.phy_ready_o(mem_mmu_ready),
		.mmu_busy_o(mem_mmu_busy),

		.page_fault_en_o(mem_page_fault_en),
		.inst_page_fault_o(),
		.store_page_fault_o(mem_store_fault_en),
		.load_page_fault_o(mem_load_fault_en),

		.wb_cyc_o(wb1_mmu_cyc_o),
		.wb_stb_o(wb1_mmu_stb_o),
		.wb_ack_i(wb1_mmu_ack_i),
		.wb_adr_o(wb1_mmu_adr_o),
		.wb_dat_o(wb1_mmu_dat_o),
		.wb_dat_i(wb1_mmu_dat_i),
		.wb_sel_o(wb1_mmu_sel_o),
		.wb_we_o(wb1_mmu_we_o)
	);

	logic wb1_cyc_o;
	logic wb1_stb_o;
	logic wb1_ack_i;
	logic [ADDR_WIDTH-1:0] wb1_adr_o;
	logic [DATA_WIDTH-1:0] wb1_dat_o;
	logic [DATA_WIDTH-1:0] wb1_dat_i;
	logic [DATA_WIDTH/8-1:0] wb1_sel_o;
	logic wb1_we_o;

	mmu_master_mux mem_mmu_master_mux (
		.sel_i(mem_mmu_busy),

		.mmu_wb_cyc_i(wb1_mmu_cyc_o),
		.mmu_wb_stb_i(wb1_mmu_stb_o),
		.mmu_wb_ack_o(wb1_mmu_ack_i),
		.mmu_wb_adr_i(wb1_mmu_adr_o),
		.mmu_wb_dat_i(wb1_mmu_dat_o),
		.mmu_wb_dat_o(wb1_mmu_dat_i),
		.mmu_wb_sel_i(wb1_mmu_sel_o),
		.mmu_wb_we_i(wb1_mmu_we_o),

		.master_wb_cyc_i(wb1_master_cyc_o),
		.master_wb_stb_i(wb1_master_stb_o),
		.master_wb_ack_o(wb1_master_ack_i),
		.master_wb_adr_i(wb1_master_adr_o),
		.master_wb_dat_i(wb1_master_dat_o),
		.master_wb_dat_o(wb1_master_dat_i),
		.master_wb_sel_i(wb1_master_sel_o),
		.master_wb_we_i(wb1_master_we_o),

		.wb_cyc_o(wb1_cyc_o),
		.wb_stb_o(wb1_stb_o),
		.wb_ack_i(wb1_ack_i),
		.wb_adr_o(wb1_adr_o),
		.wb_dat_o(wb1_dat_o),
		.wb_dat_i(wb1_dat_i),
		.wb_sel_o(wb1_sel_o),
		.wb_we_o(wb1_we_o)
	);

	logic [DATA_WIDTH-1:0] mem_reg_dat;

	mem_writeback_mux mem_writeback_mux (
		.dm_dat_i(mem_dm_dat),
		.alu_y_i(mem_alu_y),
		.pc_i(mem_pc),
		.writeback_mux_sel_i(mem_writeback_mux_sel),
		.writeback_mux_o(mem_reg_dat)
    );

	mem_exception_detector mem_exception_detector (
		.exception_en_i(mem_exception_en),
		.exception_pc_i(mem_exception_pc),
		.exception_privilege_mode_i(mem_exception_privilege_mode),

		.interrupt_en_i(mtime_interrupt_en),
		.interrupt_pc_i(mtime_interrupt_pc),

		.mem_load_fault_en_i(mem_load_fault_en),
		.mem_load_fault_pc_i(id_exception_pc),
		.mem_store_fault_en_i(mem_store_fault_en),
		.mem_store_fault_pc_i(id_exception_pc),

		.load_misalign_en_i(mem_load_misalign_en),
		.load_misalign_pc_i(id_exception_pc),
		.store_misalign_en_i(mem_store_misalign_en),
		.store_misalign_pc_i(id_exception_pc),

		.csr_exception_en_o(csr_exception_en),
		.csr_exception_pc_o(csr_exception_pc),
		.csr_exception_privilege_mode_o(csr_exception_privilege_mode)
    );

	//* =============== MEM-WB =============== *//

	logic mem_writeback_stall;
	logic mem_writeback_bubble;

    logic [1:0] writeback_instruction_mode;

	mem_writeback_regs mem_writeback_regs (
		.clk_i(sys_clk),
		.rst_i(sys_rst),
		.stall_i(mem_writeback_stall),
		.bubble_i(mem_writeback_bubble),

		// [MEM] ~ [WRITEBACK]
		.writeback_data_i(mem_reg_dat),
		.writeback_data_o(writeback_reg_dat),
		.rd_i(mem_rd),
		.rd_o(writeback_rd),
		.reg_we_i(mem_reg_we),
		.reg_we_o(writeback_reg_we),

		// [CSR]
		.csr_we_i(mem_csr_we),
		.csr_we_o(writeback_csr_we),
		.csr_waddr_i(mem_csr_waddr),
		.csr_waddr_o(writeback_csr_waddr),
		.csr_wdata_i(mem_csr_wdata),
		.csr_wdata_o(writeback_csr_wdata),
		.instruction_mode_i(mem_instruction_mode),
		.instruction_mode_o(writeback_instruction_mode)
	);

	//* ============== CONTROLLER ============== *//

	logic mt_mtime_we;
	logic mt_mtimecmp_we;
	logic mt_high_we;
	logic [DATA_WIDTH-1:0] mt_mtime_wdata;
	logic [2*DATA_WIDTH-1:0] mt_mtime;
	logic [2*DATA_WIDTH-1:0] mt_mtimecmp;
	logic timer_interrupt;

	mtime_reg_controller mtime_reg_controller (
		.clk_i(sys_clk),
		.rst_i(sys_rst),

		.mtime_we_i(mt_mtime_we),
		.mtimecmp_we_i(mt_mtimecmp_we),
		.mtime_wdata_i(mt_mtime_wdata),
		.high_we_i(mt_high_we),

		.mtime_o(mt_mtime),
		.mtimecmp_o(mt_mtimecmp),
		.timer_interrupt_o(timer_interrupt)
	);

	logic exe_br_miss;

	hazard_controller hazard_controller (
		.im_ready_i(im_ready),
		.dm_ready_i(dm_ready),

		.id_rs1_i(id_rs1),
		.id_rs2_i(id_rs2),
		.exe_rd_i(exe_rd),
		.mem_rd_i(mem_rd),
		.writeback_rd_i(writeback_rd),

		.br_miss_i(exe_br_miss),
		.cache_en_i(if_cache_en),
		.exe_reg_we_i(exe_reg_we),
		.mem_reg_we_i(mem_reg_we),
		.writeback_reg_we_i(writeback_reg_we),

		.exe_dm_en_i(exe_dm_en),
		.exe_dm_we_i(exe_dm_we),

		.if_pc_i(if_pc),
		.id_pc_i(id_pc),
		.exe_pc_i(exe_pc),
		.alu_y_i(exe_alu_y),

		.id_instruction_mode_i(id_instruction_mode),
		.exe_instruction_mode_i(exe_instruction_mode),
		.mem_instruction_mode_i(mem_instruction_mode),
		.writeback_instruction_mode_i(writeback_instruction_mode),

		.exception_en_i(csr_exception_en),
		.interrupt_en_i(mtime_interrupt_en),

		.if_mmu_ready_i(if_mmu_ready),
		.mem_mmu_ready_i(mem_mmu_ready),

		.pc_sel_o(pc_sel),
		.pc_stall_o(pc_stall),
		.if_id_stall_o(if_id_stall),
		.if_id_bubble_o(if_id_bubble),
		.id_exe_stall_o(id_exe_stall),
		.id_exe_bubble_o(id_exe_bubble),
		.exe_mem_stall_o(exe_mem_stall),
		.exe_mem_bubble_o(exe_mem_bubble),
		.mem_wb_stall_o(mem_writeback_stall),
		.mem_wb_bubble_o(mem_writeback_bubble)
	);

	forwarding_controller forwarding_controller (
		.id_rs1_i(id_rs1),
		.id_rs2_i(id_rs2),
		.exe_rd_i(exe_rd),
		.mem_rd_i(mem_rd),
		.writeback_rd_i(writeback_rd),

		.exe_reg_we_i(exe_reg_we),
		.mem_reg_we_i(mem_reg_we),
		.writeback_reg_we_i(writeback_reg_we),

		.exe_data_i(exe_alu_y),
		.mem_data_i(mem_reg_dat),
		.writeback_data_i(writeback_reg_dat),

		.exe_writeback_mux_sel_i(exe_writeback_mux_sel),

		.rs1_dat_o(forward_rs1_dat),
		.rs2_dat_o(forward_rs2_dat),
		.rs1_dat_sel_o(forward_rs1_dat_sel),
		.rs2_dat_sel_o(forward_rs2_dat_sel)
	);

	jump_predict #(
		.DATA_WIDTH(32),
		.ADDR_WIDTH(32)
	) jump_predict (
		.clk_i(sys_clk),
		.rst_i(sys_rst),

		.if_pc_i(if_pc),
		.if_inst_i(if_inst),
		.if_next_pc_o(if_jp_pc),
		.if_predict_o(if_predict),

		.exe_pc_i(exe_pc),
		.br_predict_i(exe_predict),
		.br_target_i(exe_alu_y),
		.br_taken_i(exe_br_taken),
		.br_en_i(exe_br_en),
		.br_op_i(exe_br_op),
		.clear_cache_i(exe_clear_cache),

		.br_miss_o(exe_br_miss),
		.br_next_o(exe_jp_pc)
	);

	if_icache #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
	) if_icache (
		.clk_i(sys_clk),
		.rst_i(sys_rst),

		.if_pc_i(wb0_adr_o),

		.if_r_inst_o(if_cache_inst),
		.if_cache_en_o(if_cache_en),

		.exe_clear_cache_i(exe_clear_cache),
		.if_cache_we_i(if_cache_we),
		.if_w_inst_i(if_mem_inst)
	);

	if_inst_mux #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
	) if_inst_mux (
    	.cache_inst_i(if_cache_inst),
    	.mem_inst_i(if_mem_inst),
        .cache_en_i(if_cache_en),
        .inst_o(if_inst),
		.clear_cache_o(if_clear_cache)
	);

	//* ================ ARBITER ================ *//
	//* ========== 0 <-> DM, 1 <-> IM =========== *//

	logic [ADDR_WIDTH-1:0] wbs_adr_o;
    logic [DATA_WIDTH-1:0] wbs_dat_i;
    logic [DATA_WIDTH-1:0] wbs_dat_o;
    logic wbs_we_o;
    logic [3:0] wbs_sel_o;
    logic wbs_stb_o;
    logic wbs_ack_i;
    logic wbs_err_i;
    logic wbs_rty_i;
    logic wbs_cyc_o;

    wb_arbiter_2 wb_arbiter_2 (
        .clk(sys_clk),
        .rst(sys_rst),

        .wbm0_adr_i(wb0_adr_o),
        .wbm0_dat_i(wb0_dat_o),
        .wbm0_dat_o(wb0_dat_i),
        .wbm0_we_i(wb0_we_o),
        .wbm0_sel_i(wb0_sel_o),
        .wbm0_stb_i(wb0_stb_o),
        .wbm0_ack_o(wb0_ack_i),
        .wbm0_err_o(),
        .wbm0_rty_o(),
        .wbm0_cyc_i(wb0_cyc_o),
        
        .wbm1_adr_i(wb1_adr_o),
        .wbm1_dat_i(wb1_dat_o),
        .wbm1_dat_o(wb1_dat_i),
        .wbm1_we_i(wb1_we_o),
        .wbm1_sel_i(wb1_sel_o),
        .wbm1_stb_i(wb1_stb_o),
        .wbm1_ack_o(wb1_ack_i),
        .wbm1_err_o(),
        .wbm1_rty_o(),
        .wbm1_cyc_i(wb1_cyc_o),

        .wbs_adr_o(wbs_adr_o),
        .wbs_dat_i(wbs_dat_o),
        .wbs_dat_o(wbs_dat_i),
        .wbs_we_o(wbs_we_o),
        .wbs_sel_o(wbs_sel_o),
        .wbs_stb_o(wbs_stb_o),
        .wbs_ack_i(wbs_ack_i),
        .wbs_err_i(wbs_err_i),
        .wbs_rty_i(wbs_rty_i),
        .wbs_cyc_o(wbs_cyc_o)
    );

	//* ================ WB_MUX ================ *//

    logic wbs0_cyc_o;
    logic wbs0_stb_o;
    logic wbs0_ack_i;
    logic [ADDR_WIDTH-1:0] wbs0_adr_o;
    logic [DATA_WIDTH-1:0] wbs0_dat_o;
    logic [DATA_WIDTH-1:0] wbs0_dat_i;
    logic [3:0] wbs0_sel_o;
    logic wbs0_we_o;

    logic wbs1_cyc_o;
    logic wbs1_stb_o;
    logic wbs1_ack_i;
    logic [ADDR_WIDTH-1:0] wbs1_adr_o;
    logic [DATA_WIDTH-1:0] wbs1_dat_o;
    logic [DATA_WIDTH-1:0] wbs1_dat_i;
    logic [3:0] wbs1_sel_o;
    logic wbs1_we_o;

    logic wbs2_cyc_o;
    logic wbs2_stb_o;
    logic wbs2_ack_i;
    logic [ADDR_WIDTH-1:0] wbs2_adr_o;
    logic [DATA_WIDTH-1:0] wbs2_dat_o;
    logic [DATA_WIDTH-1:0] wbs2_dat_i;
    logic [3:0] wbs2_sel_o;
    logic wbs2_we_o;

	logic wbs3_cyc_o;
    logic wbs3_stb_o;
    logic wbs3_ack_i;
    logic [ADDR_WIDTH-1:0] wbs3_adr_o;
    logic [DATA_WIDTH-1:0] wbs3_dat_o;
    logic [DATA_WIDTH-1:0] wbs3_dat_i;
    logic [3:0] wbs3_sel_o;
    logic wbs3_we_o;

    wb_mux_4 wb_mux_4 (
        .clk(sys_clk),
        .rst(sys_rst),

        .wbm_adr_i(wbs_adr_o),
        .wbm_dat_i(wbs_dat_i),
        .wbm_dat_o(wbs_dat_o),
        .wbm_we_i (wbs_we_o),
        .wbm_sel_i(wbs_sel_o),
        .wbm_stb_i(wbs_stb_o),
        .wbm_ack_o(wbs_ack_i),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(wbs_cyc_o),

        // Slave interface 0 (to BaseRAM controller)
        // Address range: 0x8000_0000 ~ 0x803F_FFFF
        .wbs0_addr    (32'h8000_0000),
        .wbs0_addr_msk(32'hFFC0_0000),

        .wbs0_adr_o(wbs0_adr_o),
        .wbs0_dat_i(wbs0_dat_i),
        .wbs0_dat_o(wbs0_dat_o),
        .wbs0_we_o (wbs0_we_o),
        .wbs0_sel_o(wbs0_sel_o),
        .wbs0_stb_o(wbs0_stb_o),
        .wbs0_ack_i(wbs0_ack_i),
        .wbs0_err_i('0),
        .wbs0_rty_i('0),
        .wbs0_cyc_o(wbs0_cyc_o),

        // Slave interface 1 (to ExtRAM controller)
        // Address range: 0x8040_0000 ~ 0x807F_FFFF
        .wbs1_addr    (32'h8040_0000),
        .wbs1_addr_msk(32'hFFC0_0000),

        .wbs1_adr_o(wbs1_adr_o),
        .wbs1_dat_i(wbs1_dat_i),
        .wbs1_dat_o(wbs1_dat_o),
        .wbs1_we_o (wbs1_we_o),
        .wbs1_sel_o(wbs1_sel_o),
        .wbs1_stb_o(wbs1_stb_o),
        .wbs1_ack_i(wbs1_ack_i),
        .wbs1_err_i('0),
        .wbs1_rty_i('0),
        .wbs1_cyc_o(wbs1_cyc_o),

        // Slave interface 2 (to UART controller)
        // Address range: 0x1000_0000 ~ 0x1000_FFFF
        .wbs2_addr    (32'h1000_0000),
        .wbs2_addr_msk(32'hFFFF_0000),

        .wbs2_adr_o(wbs2_adr_o),
        .wbs2_dat_i(wbs2_dat_i),
        .wbs2_dat_o(wbs2_dat_o),
        .wbs2_we_o (wbs2_we_o),
        .wbs2_sel_o(wbs2_sel_o),
        .wbs2_stb_o(wbs2_stb_o),
        .wbs2_ack_i(wbs2_ack_i),
        .wbs2_err_i('0),
        .wbs2_rty_i('0),
        .wbs2_cyc_o(wbs2_cyc_o),

		// Slave interface 3 (to Blockram controller)
        // Address range: 0x4000_0000 ~ 0x400F_FFFF
        .wbs3_addr    (32'h4000_0000),
        .wbs3_addr_msk(32'hFFF0_0000),

        .wbs3_adr_o(wbs3_adr_o),
        .wbs3_dat_i(wbs3_dat_i),
        .wbs3_dat_o(wbs3_dat_o),
        .wbs3_we_o (wbs3_we_o),
        .wbs3_sel_o(wbs3_sel_o),
        .wbs3_stb_o(wbs3_stb_o),
        .wbs3_ack_i(wbs3_ack_i),
        .wbs3_err_i('0),
        .wbs3_rty_i('0),
        .wbs3_cyc_o(wbs3_cyc_o)
    );

	//* =============== WB_SLAVE =============== *//

    sram_controller #(
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) sram_controller_base (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i(wbs0_cyc_o),
        .wb_stb_i(wbs0_stb_o),
        .wb_ack_o(wbs0_ack_i),
        .wb_adr_i(wbs0_adr_o),
        .wb_dat_i(wbs0_dat_o),
        .wb_dat_o(wbs0_dat_i),
        .wb_sel_i(wbs0_sel_o),
        .wb_we_i (wbs0_we_o),

        // To SRAM chip
        .sram_addr(base_ram_addr),
        .sram_data(base_ram_data),
        .sram_ce_n(base_ram_ce_n),
        .sram_oe_n(base_ram_oe_n),
        .sram_we_n(base_ram_we_n),
        .sram_be_n(base_ram_be_n)
    );

    sram_controller #(
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) sram_controller_ext (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i(wbs1_cyc_o),
        .wb_stb_i(wbs1_stb_o),
        .wb_ack_o(wbs1_ack_i),
        .wb_adr_i(wbs1_adr_o),
        .wb_dat_i(wbs1_dat_o),
        .wb_dat_o(wbs1_dat_i),
        .wb_sel_i(wbs1_sel_o),
        .wb_we_i (wbs1_we_o),

        // To SRAM chip
        .sram_addr(ext_ram_addr),
        .sram_data(ext_ram_data),
        .sram_ce_n(ext_ram_ce_n),
        .sram_oe_n(ext_ram_oe_n),
        .sram_we_n(ext_ram_we_n),
        .sram_be_n(ext_ram_be_n)
    );

    uart_controller #(
        .CLK_FREQ(50_000_000),
        .BAUD    (115200)
    ) uart_controller (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        .wb_cyc_i(wbs2_cyc_o),
        .wb_stb_i(wbs2_stb_o),
        .wb_ack_o(wbs2_ack_i),
        .wb_adr_i(wbs2_adr_o),
        .wb_dat_i(wbs2_dat_o),
        .wb_dat_o(wbs2_dat_i),
        .wb_sel_i(wbs2_sel_o),
        .wb_we_i (wbs2_we_o),

        // to UART pins
        .uart_txd_o(txd),
        .uart_rxd_i(rxd)
    );

	bram_controller #(
        .BRAM_ADDR_WIDTH(19),
        .BRAM_DATA_WIDTH(8)
    ) bram_controller (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i(wbs3_cyc_o),
        .wb_stb_i(wbs3_stb_o),
        .wb_ack_o(wbs3_ack_i),
        .wb_adr_i(wbs3_adr_o),
        .wb_dat_i(wbs3_dat_o),
        .wb_dat_o(wbs3_dat_i),
        .wb_sel_i(wbs3_sel_o),
        .wb_we_i (wbs3_we_o),

        // To BRAM chip
        .bram_addr(bram_addr_a),
        .bram_data_in(bram_data_in_a),
		.bram_data_out(bram_data_out_a),
        .bram_en(bram_en_a),
        .bram_we(bram_we_a)
    );


	vga #(20, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    	.clk        (sys_clk),
    	.hdata      (),        // 横坐标
    	.vdata      (),             // 纵坐标


		.vga_bram_en(vga_bram_en),
		.vga_bram_addr(vga_bram_addr),
		.vga_bram_data(vga_bram_data),

	    .hsync_reg      (video_hsync),
    	.vsync_reg      (video_vsync),
      	.vga_data_enable(video_de),
		.video_red		(video_red),
		.video_green	(video_green),
		.video_blue     (video_blue)
    );

endmodule
