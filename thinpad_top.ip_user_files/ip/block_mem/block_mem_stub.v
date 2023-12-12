// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2.1 (win64) Build 2729669 Thu Dec  5 04:49:17 MST 2019
// Date        : Mon Dec 11 21:09:37 2023
// Host        : DESKTOP-DSGBA2I running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/15536/Desktop/learn/2023_1/cod/cod23-grp25/thinpad_top.srcs/sources_1/ip/block_mem/block_mem_stub.v
// Design      : block_mem
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg676-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2.1" *)
module block_mem(clka, ena, wea, addra, dina, douta, clkb, enb, web, addrb, 
  dinb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[3:0],addra[16:0],dina[31:0],douta[31:0],clkb,enb,web[3:0],addrb[16:0],dinb[31:0],doutb[31:0]" */;
  input clka;
  input ena;
  input [3:0]wea;
  input [16:0]addra;
  input [31:0]dina;
  output [31:0]douta;
  input clkb;
  input enb;
  input [3:0]web;
  input [16:0]addrb;
  input [31:0]dinb;
  output [31:0]doutb;
endmodule
