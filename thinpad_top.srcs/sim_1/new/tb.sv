`timescale 1ns / 1ps
module tb;

	wire clk_50M, clk_11M0592;

	reg push_btn;   // BTN5 ��ť??�أ���������·������ʱΪ 1
	reg reset_btn;  // BTN6 ��λ��ť����������·������ʱ?? 1

	reg [3:0] touch_btn; // BTN1~BTN4����ť���أ�����ʱΪ 1
	reg [31:0] dip_sw;   // 32 λ���뿪�أ�������ON��ʱ?? 1

	wire [15:0] leds;  // 16 λ LED������? 1 ����
	wire [7:0] dpy0;   // ����ܵ�λ�źţ�����С���㣬��� 1 ����
	wire [7:0] dpy1;   // ����ܸ�λ�źţ�����С���㣬��� 1 ����

	wire txd;  // ֱ�����ڷ�???��
	wire rxd;  // ֱ�����ڽ���??

	wire [31:0] base_ram_data;  // BaseRAM ���ݣ��� 8 λ�� CPLD ���ڿ�������??
	wire [19:0] base_ram_addr;  // BaseRAM ��ַ
	wire[3:0] base_ram_be_n;    // BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��???? 0
	wire base_ram_ce_n;  // BaseRAM Ƭ???������??
	wire base_ram_oe_n;  // BaseRAM ��ʹ�ܣ�����??
	wire base_ram_we_n;  // BaseRAM дʹ�ܣ�����??

	wire [31:0] ext_ram_data;  // ExtRAM ����
	wire [19:0] ext_ram_addr;  // ExtRAM ��ַ
	wire[3:0] ext_ram_be_n;    // ExtRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��???? 0
	wire ext_ram_ce_n;  // ExtRAM Ƭ???������??
	wire ext_ram_oe_n;  // ExtRAM ��ʹ�ܣ�����??
	wire ext_ram_we_n;  // ExtRAM дʹ�ܣ�����??

	wire [22:0] flash_a;  // Flash ��ַ��a0 ���� 8bit ģʽ��Ч??16bit ģʽ����??
	wire [15:0] flash_d;  // Flash ����
	wire flash_rp_n;   // Flash ��λ�źţ�����Ч
	wire flash_vpen;   // Flash д�����źţ��͵�ƽʱ���ܲ�������??
	wire flash_ce_n;   // Flash Ƭ???�źţ�����??
	wire flash_oe_n;   // Flash ��ʹ���źţ�����??
	wire flash_we_n;   // Flash дʹ���źţ�����??
	wire flash_byte_n; // Flash 8bit ģʽѡ�񣬵���Ч����ʹ�� flash ?? 16 λģʽʱ����?? 1

	wire uart_rdn;  // �������źţ�����??
	wire uart_wrn;  // д�����źţ�����??
	wire uart_dataready;  // ��������׼��??
	wire uart_tbre;  // ��???���ݱ�??
	wire uart_tsre;  // ���ݷ�???��ϱ�????

	// Windows ??Ҫע��·���ָ�����ת�壬���� "D:\\foo\\bar.bin"
    //	parameter BASE_RAM_INIT_FILE = "C:\\Users\\cyh\\Desktop\\rv-2023\\cod23-grp25\\thinpad_top.srcs\\sources_1\\new\\kernel-rv32-no16550.bin"; // BaseRAM ��ʼ���ļ������޸�Ϊʵ�ʵľ���·??
	parameter BASE_RAM_INIT_FILE = "C:\\rv\\asmcode\\test_int_instr.bin"; // BaseRAM ��ʼ���ļ������޸�Ϊʵ�ʵľ���·??
	parameter EXT_RAM_INIT_FILE = "/tmp/eram.bin";  // ExtRAM ��ʼ���ļ������޸�Ϊʵ�ʵľ���·??
	parameter FLASH_INIT_FILE = "/tmp/kernel.elf";  // Flash ��ʼ���ļ������޸�Ϊʵ�ʵľ���·??

	initial begin
		// ����������Զ�������������У����磺
		push_btn = 0;

		#100;
		reset_btn = 1;
		#100;
		reset_btn = 0;
	end

	// �������û���??
	thinpad_top dut (
		.clk_50M(clk_50M),
		.clk_11M0592(clk_11M0592),
		.push_btn(push_btn),
		.reset_btn(reset_btn),
		.touch_btn(touch_btn),
		.dip_sw(dip_sw),
		.leds(leds),
		.dpy1(dpy1),
		.dpy0(dpy0),
		.txd(txd),
		.rxd(rxd),
		.uart_rdn(uart_rdn),
		.uart_wrn(uart_wrn),
		.uart_dataready(uart_dataready),
		.uart_tbre(uart_tbre),
		.uart_tsre(uart_tsre),
		.base_ram_data(base_ram_data),
		.base_ram_addr(base_ram_addr),
		.base_ram_ce_n(base_ram_ce_n),
		.base_ram_oe_n(base_ram_oe_n),
		.base_ram_we_n(base_ram_we_n),
		.base_ram_be_n(base_ram_be_n),
		.ext_ram_data(ext_ram_data),
		.ext_ram_addr(ext_ram_addr),
		.ext_ram_ce_n(ext_ram_ce_n),
		.ext_ram_oe_n(ext_ram_oe_n),
		.ext_ram_we_n(ext_ram_we_n),
		.ext_ram_be_n(ext_ram_be_n),
		.flash_d(flash_d),
		.flash_a(flash_a),
		.flash_rp_n(flash_rp_n),
		.flash_vpen(flash_vpen),
		.flash_oe_n(flash_oe_n),
		.flash_ce_n(flash_ce_n),
		.flash_byte_n(flash_byte_n),
		.flash_we_n(flash_we_n)
	);
	// ʱ��??
	clock osc (
		.clk_11M0592(clk_11M0592),
		.clk_50M    (clk_50M)
	);
	// CPLD ���ڷ���ģ��
	cpld_model cpld (
		.clk_uart(clk_11M0592),
		.uart_rdn(uart_rdn),
		.uart_wrn(uart_wrn),
		.uart_dataready(uart_dataready),
		.uart_tbre(uart_tbre),
		.uart_tsre(uart_tsre),
		.data(base_ram_data[7:0])
	);
	// ֱ�����ڷ���ģ��
	uart_model uart (
		.rxd (txd),
		.txd (rxd)
	);
	// BaseRAM ����ģ��
	sram_model base1 (
		.DataIO(base_ram_data[15:0]),
		.Address(base_ram_addr[19:0]),
		.OE_n(base_ram_oe_n),
		.CE_n(base_ram_ce_n),
		.WE_n(base_ram_we_n),
		.LB_n(base_ram_be_n[0]),
		.UB_n(base_ram_be_n[1])
	);
	sram_model base2 (
		.DataIO(base_ram_data[31:16]),
		.Address(base_ram_addr[19:0]),
		.OE_n(base_ram_oe_n),
		.CE_n(base_ram_ce_n),
		.WE_n(base_ram_we_n),
		.LB_n(base_ram_be_n[2]),
		.UB_n(base_ram_be_n[3])
	);
	// ExtRAM ����ģ��
	sram_model ext1 (
		.DataIO(ext_ram_data[15:0]),
		.Address(ext_ram_addr[19:0]),
		.OE_n(ext_ram_oe_n),
		.CE_n(ext_ram_ce_n),
		.WE_n(ext_ram_we_n),
		.LB_n(ext_ram_be_n[0]),
		.UB_n(ext_ram_be_n[1])
	);
	sram_model ext2 (
		.DataIO(ext_ram_data[31:16]),
		.Address(ext_ram_addr[19:0]),
		.OE_n(ext_ram_oe_n),
		.CE_n(ext_ram_ce_n),
		.WE_n(ext_ram_we_n),
		.LB_n(ext_ram_be_n[2]),
		.UB_n(ext_ram_be_n[3])
	);
	// Flash ����ģ��
	x28fxxxp30 #(
		.FILENAME_MEM(FLASH_INIT_FILE)
	) flash (
		.A   (flash_a[1+:22]),
		.DQ  (flash_d),
		.W_N (flash_we_n),      // Write Enable 
		.G_N (flash_oe_n),      // Output Enable
		.E_N (flash_ce_n),      // Chip Enable
		.L_N (1'b0),            // Latch Enable
		.K   (1'b0),            // Clock
		.WP_N(flash_vpen),      // Write Protect
		.RP_N(flash_rp_n),      // Reset/Power-Down
		.VDD ('d3300),
		.VDDQ('d3300),
		.VPP ('d1800),
		.Info(1'b1)
	);

	initial begin
		wait (flash_byte_n == 1'b0);
		$display("8-bit Flash interface is not supported in simulation!");
		$display("Please tie flash_byte_n to high");
		$stop;
	end

	// ���ļ���?? BaseRAM
	initial begin
		reg [31:0] tmp_array[0:1048575];
		integer n_File_ID, n_Init_Size;
		n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
		if (!n_File_ID) begin
			n_Init_Size = 0;
			$display("Failed to open BaseRAM init file");
		end else begin
			n_Init_Size = $fread(tmp_array, n_File_ID);
			n_Init_Size /= 4;
			$fclose(n_File_ID);
		end
		$display("BaseRAM Init Size(words): %d", n_Init_Size);
		for (integer i = 0; i < n_Init_Size; i++) begin
			base1.mem_array0[i] = tmp_array[i][24+:8];
			base1.mem_array1[i] = tmp_array[i][16+:8];
			base2.mem_array0[i] = tmp_array[i][8+:8];
			base2.mem_array1[i] = tmp_array[i][0+:8];
		end
	end

  // ���ļ���?? ExtRAM
	initial begin
		reg [31:0] tmp_array[0:1048575];
		integer n_File_ID, n_Init_Size;
		n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
		if (!n_File_ID) begin
			n_Init_Size = 0;
			$display("Failed to open ExtRAM init file");
		end else begin
			n_Init_Size = $fread(tmp_array, n_File_ID);
			n_Init_Size /= 4;
			$fclose(n_File_ID);
		end
		$display("ExtRAM Init Size(words): %d", n_Init_Size);
		for (integer i = 0; i < n_Init_Size; i++) begin
			ext1.mem_array0[i] = tmp_array[i][24+:8];
			ext1.mem_array1[i] = tmp_array[i][16+:8];
			ext2.mem_array0[i] = tmp_array[i][8+:8];
			ext2.mem_array1[i] = tmp_array[i][0+:8];
		end
	end
endmodule
