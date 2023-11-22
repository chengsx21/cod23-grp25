`default_nettype none
`timescale 1ns / 1ps

module button_in(
    input wire clk,
    input wire reset,
    input wire push_btn,
    output wire trigger
    );

    reg push_btn_reg;
    reg trigger_reg;

    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            push_btn_reg <= 1'b0;
            trigger_reg <= 1'b0;
        end else begin
            push_btn_reg <= push_btn;
            if (push_btn && !push_btn_reg) begin
                trigger_reg <= 1'b1;
            end else begin
                trigger_reg <= 1'b0;
            end
        end
    end

    assign trigger = trigger_reg;
    
endmodule
