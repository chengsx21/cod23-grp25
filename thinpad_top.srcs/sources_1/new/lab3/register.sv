`timescale 1ns / 1ps

module register(
    input wire clk,
    input wire reset,

    input wire [4:0] waddr,
    input wire [15:0] wdata,
    input wire we,
    input wire [4:0] raddr_a,
    output reg [15:0] rdata_a,
    input wire [4:0] raddr_b,
    output reg [15:0] rdata_b
    );

    reg [31:0][15:0] regs;

    always_comb begin
        if (raddr_a == 5'b00000) begin
            rdata_a = 16'h0000;
        end else begin
            rdata_a = regs[raddr_a];
        end 
        if (raddr_b == 5'b00000) begin
            rdata_b = 16'h0000;
        end else begin
            rdata_b = regs[raddr_b];
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            for (integer i = 0; i < 32; i = i + 1) begin
                regs[i] <= 16'h0000;
            end
        end
        else if (we && (waddr != 5'b00000)) begin
            regs[waddr] <= wdata;
        end
    end

endmodule
