module exe_alu #(
    parameter DATA_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] a_i,
    input wire [DATA_WIDTH-1:0] b_i,
    input wire [3:0] op_i,
    output reg [DATA_WIDTH-1:0] y_i
    );

    always_comb begin
        case (op_i)
            // 1 -> PLUS
            4'b0001: y_i = a_i + b_i;
            // 2 -> MINUS
            4'b0010: y_i = a_i - b_i;
            // 3 -> AND
            4'b0011: y_i = a_i & b_i;
            // 4 -> OR
            4'b0100: y_i = a_i | b_i;
            // 5 -> XOR
            4'b0101: y_i = a_i ^ b_i;
            // 6 -> NOT
            4'b0110: y_i = ~a_i;
            // 7 -> LSHIFT
            4'b0111: y_i = a_i << b_i[4:0];
            // 8 -> RSHIFT
            4'b1000: y_i = a_i >> b_i[4:0];
            // 9 -> ARSHIFT
            4'b1001: y_i = $signed(a_i) >>> b_i[4:0];
            // 10 -> ROTL
            4'b1010: y_i = (a_i << b_i[4:0]) | (a_i >> (DATA_WIDTH - b_i[4:0]));
            // 11 -> PCNT
            4'b1011: y_i = $countones(a_i);
            // 12 -> PACK
            4'b1100: y_i = {b_i[DATA_WIDTH/2-1:0], a_i[DATA_WIDTH/2-1:0]};
            // 13 -> MINU
            4'b1101: y_i = a_i < b_i ? a_i : b_i;
            // 0 -> NOP
            default: y_i = {DATA_WIDTH{1'b0}};
        endcase
    end
endmodule
