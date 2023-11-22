`default_nettype none

module lab2_top (
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

	logic trigger;
	logic [3:0] count;

	counter u_counter (
		.clk    (clk_10M),
		.reset  (reset_of_clk10M),
		.trigger(trigger),
		.count  (count)
	);

	button_in u_button_in (
		.clk     (clk_10M),
		.reset   (reset_of_clk10M),

		.push_btn(push_btn),
		.trigger (trigger)
	);

	SEG7_LUT u_SEG7_LUT (
		.iDIG (count),
		.oSEG1(dpy0)
	);

endmodule
