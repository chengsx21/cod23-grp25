`timescale 1ns / 1ps
module lab3_tb;

  wire clk_50M, clk_11M0592;

  reg push_btn;
  reg reset_btn;

  reg [3:0] touch_btn;
  reg [31:0] dip_sw;

  wire [15:0] leds;
  wire [7:0] dpy0;
  wire [7:0] dpy1;

  `define inst_rtype(rd, rs1, rs2, op) \
    {7'b0, rs2, rs1, 3'b0, rd, op, 3'b001}

  `define inst_itype(rd, imm, op) \
    {imm, 4'b0, rd, op, 3'b010}
  
  `define inst_poke(rd, imm) `inst_itype(rd, imm, 4'b0001)
  `define inst_peek(rd, imm) `inst_itype(rd, imm, 4'b0010)

  // opcode table
  typedef enum logic [3:0] {
    ADD = 4'b0001,
    SUB = 4'b0010,
    AND = 4'b0011,
    OR  = 4'b0100,
    XOR = 4'b0101,
    NOT = 4'b0110,
    SLL = 4'b0111,
    SRL = 4'b1000,
    SRA = 4'b1001,
    ROL = 4'b1010
  } opcode_t;

  logic [4:0] rs1 = 5'b00001;
  logic [4:0] rs2 = 5'b00010;
  logic [4:0] rd = 5'b00011;
  opcode_t opcode;

  task poke;
    input [4:0] rd;
    begin
      #100;
      dip_sw = `inst_poke(rd, $urandom_range(0, 65536));
      push_btn = 1;
      #100;
      push_btn = 0;
      #1000;
    end
  endtask
    
  task rtype;
    begin
      #100;
      dip_sw = `inst_rtype(rd, rs1, rs2, opcode);
      push_btn = 1;
      #100;
      push_btn = 0;
      #1000;
      opcode = opcode.next;
    end
  endtask

  initial begin
    dip_sw = 32'h0;
    touch_btn = 0;
    reset_btn = 0;
    push_btn = 0;

    #100;
    reset_btn = 1;
    #100;
    reset_btn = 0;
    #10000;

    poke(rs1);
    poke(rs2);
    poke(rd);
  
    opcode = opcode.first;
    for (int i = 0; i < 10; i++) begin
      rtype();
    end

    #1000 $finish;
  end

  lab3_top dut (
      .clk_50M(clk_50M),
      .clk_11M0592(clk_11M0592),
      .push_btn(push_btn),
      .reset_btn(reset_btn),
      .touch_btn(touch_btn),
      .dip_sw(dip_sw),
      .leds(leds),
      .dpy1(dpy1),
      .dpy0(dpy0),

      .txd(),
      .rxd(1'b1),
      .uart_rdn(),
      .uart_wrn(),
      .uart_dataready(1'b0),
      .uart_tbre(1'b0),
      .uart_tsre(1'b0),
      .base_ram_data(),
      .base_ram_addr(),
      .base_ram_ce_n(),
      .base_ram_oe_n(),
      .base_ram_we_n(),
      .base_ram_be_n(),
      .ext_ram_data(),
      .ext_ram_addr(),
      .ext_ram_ce_n(),
      .ext_ram_oe_n(),
      .ext_ram_we_n(),
      .ext_ram_be_n(),
      .flash_d(),
      .flash_a(),
      .flash_rp_n(),
      .flash_vpen(),
      .flash_oe_n(),
      .flash_ce_n(),
      .flash_byte_n(),
      .flash_we_n()
  );

  clock osc (
      .clk_11M0592(clk_11M0592),
      .clk_50M    (clk_50M)
  );

endmodule
