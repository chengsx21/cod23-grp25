module id_csr_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire [1:0] csr_op_i, // 0 For Write, 1 For Set, 2 For Clear
    input wire [11:0] csr_raddr_i,
    input wire [DATA_WIDTH-1:0] rs1_rdata_i,

    input wire csr_we_i,
    input wire [11:0] csr_waddr_i,
    input wire [DATA_WIDTH-1:0] csr_wdata_i,

    output logic [DATA_WIDTH-1:0] csr_rdata_o,
    output logic [DATA_WIDTH-1:0] csr_wdata_o
    );

    reg [ADDR_WIDTH-1:0] mtvec;
    reg [DATA_WIDTH-1:0] mscratch;
    reg [ADDR_WIDTH-1:0] mepc;
    reg [DATA_WIDTH-1:0] mcause;
    reg [DATA_WIDTH-1:0] mstatus;
    reg [DATA_WIDTH-1:0] mie;
    reg [DATA_WIDTH-1:0] mip;
    reg mtval;

    logic [DATA_WIDTH-1:0] csr_rdata;
    assign csr_rdata_o = csr_rdata;

    always_comb begin
        case (csr_raddr_i)
            12'h305: csr_rdata = mtvec;
            12'h340: csr_rdata = mscratch;
            12'h341: csr_rdata = mepc;
            12'h342: csr_rdata = mcause;
            12'h300: csr_rdata = mstatus;
            12'h304: csr_rdata = mie;
            12'h344: csr_rdata = mip;
            default: csr_rdata = {DATA_WIDTH{1'b0}};
        endcase
    end

    logic [DATA_WIDTH-1:0] csr_wdata;
    assign csr_wdata_o = csr_wdata;

    always_comb begin
        case (csr_op_i) 
            2'b00: csr_wdata = rs1_rdata_i;
            2'b01: csr_wdata = rs1_rdata_i | csr_rdata;
            2'b10: csr_wdata = ~rs1_rdata_i & csr_rdata;
            default: csr_wdata = {DATA_WIDTH{1'b0}};
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mtvec <= {ADDR_WIDTH{1'b0}};
            mscratch <= {DATA_WIDTH{1'b0}};
            mepc <= {ADDR_WIDTH{1'b0}};
            mcause <= {DATA_WIDTH{1'b0}};
            mstatus <= {DATA_WIDTH{1'b0}};
            mie <= {DATA_WIDTH{1'b0}};
            mip <= {DATA_WIDTH{1'b0}};
        end
        else if (csr_we_i) begin
            case (csr_waddr_i)
                12'h305: mtvec <= csr_wdata_i;
                12'h340: mscratch <= csr_wdata_i;
                12'h341: mepc <= csr_wdata_i;
                12'h342: mcause <= csr_wdata_i;
                12'h300: mstatus <= csr_wdata_i;
                12'h304: mie <= csr_wdata_i;
                12'h344: mip <= csr_wdata_i;
            endcase
        end
    end 
endmodule