`default_nettype none

module lab4_top (
    input wire clk_50M,     // 50MHz clock input
    input wire clk_11M0592, // 11.0592MHz clock input

    input wire push_btn,  // BTN5 debounced, pressed as signal 1
    input wire reset_btn, // BTN6 debounced, pressed as signal 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4, pressed as signal 1
    input  wire [31:0] dip_sw,     // 32bit DIP switch, set on "ON" as signal 1
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
    inout wire [31:0] base_ram_data,  // BaseRAM data, low 8 bits shared with uart controller
    output wire [19:0] base_ram_addr,  // BaseRAM address
    output wire [3:0] base_ram_be_n,  // BaseRAM byte enable signal, low level effectively
    output wire base_ram_ce_n,  // BaseRAM chip enable signal, low level effectively
    output wire base_ram_oe_n,  // BaseRAM output enable signal, low level effectively
    output wire base_ram_we_n,  // BaseRAM write enable signal, low level effectively

    // ExtRAM signal
    inout wire [31:0] ext_ram_data,  // ExtRAM data
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
	logic locked, clk_10M, clk_20M;
	pll_example clock_gen (
		// Clock in ports
		.clk_in1(clk_50M),  // Outside clock input
		// Clock out ports
		.clk_out1(clk_10M),  // Frequency set in IP config page
		.clk_out2(clk_20M),  // Frequency set in IP config page
		// Status and control signals
		.reset(reset_btn),  // PLL reset
		.locked(locked)  // PLL lock signal, 1 when stable
	);

	logic reset_of_clk10M;
	// Async reset, sync free, transform locked to reset_of_clk10M
	always_ff @(posedge clk_10M or negedge locked) begin
		if (~locked) reset_of_clk10M <= 1'b1;
		else reset_of_clk10M <= 1'b0;
	end

    /* =========== Demo code end =========== */

    logic sys_clk;
    logic sys_rst;

    assign sys_clk = clk_10M;
    assign sys_rst = reset_of_clk10M;

    // Don't use CPLD uart, disable to avoid conflict
    assign uart_rdn = 1'b1;
    assign uart_wrn = 1'b1;

    /* =========== Lab4 Master begin =========== */
    // SRAM Tester (Master) => Wishbone MUX (Slave)
    logic        wbm_cyc_o;
    logic        wbm_stb_o;
    logic        wbm_ack_i;
    logic [31:0] wbm_adr_o;
    logic [31:0] wbm_dat_o;
    logic [31:0] wbm_dat_i;
    logic [ 3:0] wbm_sel_o;
    logic        wbm_we_o;

    // Test controller signal
    logic        test_start;
    logic [31:0] random_seed;

    assign test_start  = push_btn;  // Press to start test
    assign random_seed = dip_sw;  // Input random seed

    // Output test result to LEDs
    logic test_done, test_error;
    assign leds[0] = test_done;
    assign leds[1] = test_error;
    assign leds[15:2] = '0;

    // Detailed test result for simulation, not used or connected in real board
    logic [31:0] test_error_round;  // Data error round
    logic [31:0] test_error_addr;  // Data error address
    logic [31:0] test_error_read_data;  // Data read from wrong address
    logic [31:0] test_error_expected_data;  // Data expected from wrong address

    sram_tester #(
        .ADDR_BASE(32'h8000_0000),
        .ADDR_MASK(32'h007F_FFFF)
    ) u_sram_tester (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // wishbone master
        .wb_cyc_o(wbm_cyc_o),
        .wb_stb_o(wbm_stb_o),
        .wb_ack_i(wbm_ack_i),
        .wb_adr_o(wbm_adr_o),
        .wb_dat_o(wbm_dat_o),
        .wb_dat_i(wbm_dat_i),
        .wb_sel_o(wbm_sel_o),
        .wb_we_o (wbm_we_o),

        // control input
        .start      (test_start),
        .random_seed(random_seed),

        // status output
        .done (test_done),
        .error(test_error),

        // detailed status for simulation
        .error_round        (test_error_round),
        .error_addr         (test_error_addr),
        .error_read_data    (test_error_read_data),
        .error_expected_data(test_error_expected_data)
    );

    /* =========== Lab4 Master end =========== */

    /* =========== Lab4 MUX begin =========== */
    // Wishbone MUX (Masters) => SRAM controllers
    logic wbs0_cyc_o;
    logic wbs0_stb_o;
    logic wbs0_ack_i;
    logic [31:0] wbs0_adr_o;
    logic [31:0] wbs0_dat_o;
    logic [31:0] wbs0_dat_i;
    logic [3:0] wbs0_sel_o;
    logic wbs0_we_o;

    logic wbs1_cyc_o;
    logic wbs1_stb_o;
    logic wbs1_ack_i;
    logic [31:0] wbs1_adr_o;
    logic [31:0] wbs1_dat_o;
    logic [31:0] wbs1_dat_i;
    logic [3:0] wbs1_sel_o;
    logic wbs1_we_o;

    wb_mux_2 wb_mux (
        .clk(sys_clk),
        .rst(sys_rst),

        // Master interface (to SRAM Tester)
        .wbm_adr_i(wbm_adr_o),
        .wbm_dat_i(wbm_dat_o),
        .wbm_dat_o(wbm_dat_i),
        .wbm_we_i (wbm_we_o),
        .wbm_sel_i(wbm_sel_o),
        .wbm_stb_i(wbm_stb_o),
        .wbm_ack_o(wbm_ack_i),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(wbm_cyc_o),

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
        .wbs1_cyc_o(wbs1_cyc_o)
    );

    /* =========== Lab4 MUX end =========== */

    /* =========== Lab4 Slaves begin =========== */
    sram_controller #(
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) sram_controller_base (
        .clk_i    (sys_clk),
        .rst_i    (sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i (wbs0_cyc_o),
        .wb_stb_i (wbs0_stb_o),
        .wb_ack_o (wbs0_ack_i),
        .wb_adr_i (wbs0_adr_o),
        .wb_dat_i (wbs0_dat_o),
        .wb_dat_o (wbs0_dat_i),
        .wb_sel_i (wbs0_sel_o),
        .wb_we_i  (wbs0_we_o),

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
        .clk_i    (sys_clk),
        .rst_i    (sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i (wbs1_cyc_o),
        .wb_stb_i (wbs1_stb_o),
        .wb_ack_o (wbs1_ack_i),
        .wb_adr_i (wbs1_adr_o),
        .wb_dat_i (wbs1_dat_o),
        .wb_dat_o (wbs1_dat_i),
        .wb_sel_i (wbs1_sel_o),
        .wb_we_i  (wbs1_we_o),

        // To SRAM chip
        .sram_addr(ext_ram_addr),
        .sram_data(ext_ram_data),
        .sram_ce_n(ext_ram_ce_n),
        .sram_oe_n(ext_ram_oe_n),
        .sram_we_n(ext_ram_we_n),
        .sram_be_n(ext_ram_be_n)
    );
    /* =========== Lab4 Slaves end =========== */

endmodule
