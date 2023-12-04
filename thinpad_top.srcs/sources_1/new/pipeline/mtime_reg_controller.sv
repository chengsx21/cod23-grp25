module mtime_reg_controller #(
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire mtime_we_i,
    input wire mtimecmp_we_i,
    input wire [DATA_WIDTH-1:0] mtime_wdata_i,
    input wire high_we_i,

    output logic [2*DATA_WIDTH-1:0] mtime_o,
    output logic [2*DATA_WIDTH-1:0] mtimecmp_o,
    output logic interrupt_en_o
    );

    logic [2*DATA_WIDTH-1:0] mtime_reg;
    logic [2*DATA_WIDTH-1:0] mtimecmp_reg;
    logic [15:0] counter;

    assign mtime_o = mtime_reg;
    assign mtimecmp_o = mtimecmp_reg;
    assign interrupt_en_o = (mtime_reg >= mtimecmp_reg);

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mtime_reg <= 64'h0;
            mtimecmp_reg <= 64'h100_0000_0000;
            counter <= 64'h0;
        end 

        else if (mtime_we_i) begin
            if (high_we_i) begin
                mtime_reg <= {mtime_wdata_i, mtime_reg[DATA_WIDTH-1:0]};
            end
            else begin
                mtime_reg <= {mtime_reg[2*DATA_WIDTH-1:DATA_WIDTH], mtime_wdata_i};
            end
        end

        else if (mtimecmp_we_i) begin
            if (high_we_i) begin
                mtimecmp_reg <= {mtime_wdata_i, mtimecmp_reg[DATA_WIDTH-1:0]};
            end
            else begin
                mtimecmp_reg <= {mtimecmp_reg[2*DATA_WIDTH-1:DATA_WIDTH], mtime_wdata_i};
            end
        end

        else begin
            if (counter >= 16'h100) begin
                counter <= 16'h0;
                mtime_reg <= mtime_reg + 1;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
