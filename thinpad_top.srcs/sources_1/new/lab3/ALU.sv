`timescale 1ns / 1ps

module ALU(
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [3:0] op,
    output wire [15:0] y
    );

    reg [15:0] y_reg;

    always_comb begin
        case (op)
            4'b0001: y_reg = a + b;
            4'b0010: y_reg = a - b;
            4'b0011: y_reg = a & b;
            4'b0100: y_reg = a | b;
            4'b0101: y_reg = a ^ b;
            4'b0110: y_reg = ~a;
            4'b0111: y_reg = a << b[3:0];
            4'b1000: y_reg = a >> b[3:0];
            4'b1001: y_reg = $signed(a) >>> b[3:0]; // 这里使用有符号数进行算数右移
            4'b1010: y_reg = a << b[3:0] | a >> (16 - b[3:0]);
            default: y_reg = 16'h0000;
        endcase
    end

    assign y = y_reg;
    
endmodule
