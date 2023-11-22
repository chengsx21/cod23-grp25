`default_nettype none
`timescale 1ns / 1ps

module counter(
    input wire clk,
    input wire reset,
    input wire trigger,
    output wire [3:0] count
    );

    reg [3:0] count_reg;

    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            count_reg <= 4'b0000;
        end else begin
            if (trigger && count_reg < 4'b1111) begin
                count_reg <= count_reg + 4'b0001;
            end
        end
    end

    assign count = count_reg;

endmodule
