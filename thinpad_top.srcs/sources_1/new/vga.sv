`timescale 1ns / 1ps
//
// WIDTH: bits in register hdata & vdata
// HSIZE: horizontal size of visible field 
// HFP: horizontal front of pulse
// HSP: horizontal stop of pulse
// HMAX: horizontal max size of value
// VSIZE: vertical size of visible field 
// VFP: vertical front of pulse
// VSP: vertical stop of pulse
// VMAX: vertical max size of value
// HSPP: horizontal synchro pulse polarity (0 - negative, 1 - positive)
// VSPP: vertical synchro pulse polarity (0 - negative, 1 - positive)
//
module vga #(
    parameter WIDTH = 0,
    HSIZE = 0,
    HFP = 0,
    HSP = 0,
    HMAX = 0,
    VSIZE = 0,
    VFP = 0,
    VSP = 0,
    VMAX = 0,
    HSPP = 0,
    VSPP = 0
) (
    input wire clk,
    output reg [WIDTH - 1:0] hdata,
    output reg [WIDTH - 1:0] vdata,
    

    output wire vga_bram_en,
    output wire [18:0] vga_bram_addr,
    input wire [7:0] vga_bram_data,

    output reg vga_data_enable,
    output reg hsync_reg,
    output reg vsync_reg,
    output reg [2:0] video_red,    // Red pixel, 3 bits
    output reg [2:0] video_green,  // Green pixel, 3 bits
    output reg [1:0] video_blue   // Blue pixel, 2 bits
);
    initial begin
        hdata <= '0;
        vdata <= '0;
    end
    wire hsync, vsync;

    always @(posedge clk) begin
        hsync_reg <= hsync;
        vsync_reg <= vsync;
        vga_data_enable <= vga_bram_en;
    end

    // hdata
    always @(posedge clk) begin
        if (hdata == (HMAX - 1)) hdata <= 0;
        else hdata <= hdata + 1;
    end

    // vdata
    always @(posedge clk) begin
        if (hdata == (HMAX - 1)) begin
            if (vdata == (VMAX - 1)) vdata <= 0;
            else vdata <= vdata + 1;
        end
    end

    assign vga_bram_addr = ((vdata << 9)+(vdata << 8)+ (vdata << 5) + hdata);

    always_comb begin
        video_red = vga_bram_data[7:5];
        video_green = vga_bram_data[4:2];
        video_blue = vga_bram_data[1:0];
    end


    // hsync & vsync & blank
    assign hsync = ((hdata >= HFP) && (hdata < HSP)) ? HSPP : !HSPP;
    assign vsync = ((vdata >= VFP) && (vdata < VSP)) ? VSPP : !VSPP;
    assign vga_bram_en = ((hdata < HSIZE) & (vdata < VSIZE));

endmodule
