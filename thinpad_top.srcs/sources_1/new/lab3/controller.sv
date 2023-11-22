`timescale 1ns / 1ps

module controller (
    input wire clk,
    input wire reset,

    // connect to register file
    output reg  [4:0]  rf_raddr_a,
    input  wire [15:0] rf_rdata_a,
    output reg  [4:0]  rf_raddr_b,
    input  wire [15:0] rf_rdata_b,
    output reg  [4:0]  rf_waddr,
    output reg  [15:0] rf_wdata,
    output reg  rf_we,

    // connect to ALU
    output reg  [15:0] alu_a,
    output reg  [15:0] alu_b,
    output reg  [ 3:0] alu_op,
    input  wire [15:0] alu_y,

    // control signals
    input  wire        step,    // user step
    input  wire [31:0] dip_sw,  // 32bit instruction
    output reg  [15:0] leds
);

    logic [31:0] inst_reg;  // instruction register

    // comb-logic, decode instruction
    logic is_rtype, is_itype, is_peek, is_poke;
    logic [15:0] imm;
    logic [4:0] rd, rs1, rs2;
    logic [3:0] opcode;

    always_comb begin
        is_rtype = (inst_reg[2:0] == 3'b001);
        is_itype = (inst_reg[2:0] == 3'b010);
        is_peek = is_itype && (inst_reg[6:3] == 4'b0010);
        is_poke = is_itype && (inst_reg[6:3] == 4'b0001);

        imm = inst_reg[31:16];
        rd = inst_reg[11:7];
        rs1 = inst_reg[19:15];
        rs2 = inst_reg[24:20];
        opcode = inst_reg[6:3];
    end

    // define state machine using enum
    typedef enum logic [3:0] {
        ST_INIT,
        ST_DECODE,
        ST_CALC,
        ST_READ_REG,
        ST_WRITE_REG
    } state_t;

    // state register
    state_t state;

    // state transition
    always_ff @(posedge clk) begin
        if (reset) begin
            // reset all signals
            leds <= 16'h0000;
            alu_op <= 4'b0000;
            rf_we <= 0;
            state <= ST_INIT;
        end else begin
            case (state)
                ST_INIT: begin
                    rf_we <= 0;
                    if (step) begin
                        inst_reg <= dip_sw;
                        state <= ST_DECODE;
                    end
                end

                ST_DECODE: begin
                    if (is_rtype) begin
                        // assign rs1 and rs2 to register file, read data
                        rf_raddr_a <= rs1;
                        rf_raddr_b <= rs2;
                        state <= ST_CALC;
                    end else if (is_itype) begin
                        // other instructions
                        if (is_peek) begin
                            rf_raddr_a <= rd;
                            state <= ST_READ_REG;
                        end else if (is_poke) begin
                            state <= ST_WRITE_REG;
                        end
                    end else begin
                        // unknown instruction, go back to init state
                        state <= ST_INIT;
                    end
                end

                ST_CALC: begin
                    // assign data to ALU, calculate
                    alu_a <= rf_rdata_a;
                    alu_b <= rf_rdata_b;
                    alu_op <= opcode;
                    state <= ST_WRITE_REG;
                end

                ST_WRITE_REG: begin
                    // save data to register file
                    rf_waddr <= rd;
                    rf_we <= 1;
                    if (is_rtype)
                        rf_wdata <= alu_y;
                    else
                        rf_wdata <= imm;
                    state <= ST_INIT;
                end

                ST_READ_REG: begin
                    // read data from register file, save to leds
                    leds <= rf_rdata_a;
                    state <= ST_INIT;
                end

                default: begin
                    state <= ST_INIT;
                end
            endcase
        end
    end
endmodule