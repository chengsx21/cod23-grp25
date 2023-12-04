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
    output logic timer_interrupt_o
    );

    logic [15:0] counter;
    assign timer_interrupt_o = (mtime_o >= mtimecmp_o);

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mtime_o <= 64'h0;
            mtimecmp_o <= 64'h1000_0000;
            counter <= 64'h0;
        end 

        else if (mtime_we_i) begin
            if (high_we_i) begin
                mtime_o <= {mtime_wdata_i, mtime_o[DATA_WIDTH-1:0]};
            end
            else begin
                mtime_o <= {mtime_o[2*DATA_WIDTH-1:DATA_WIDTH], mtime_wdata_i};
            end
        end

        else if (mtimecmp_we_i) begin
            if (high_we_i) begin
                mtimecmp_o <= {mtime_wdata_i, mtimecmp_o[DATA_WIDTH-1:0]};
            end
            else begin
                mtimecmp_o <= {mtimecmp_o[2*DATA_WIDTH-1:DATA_WIDTH], mtime_wdata_i};
            end
        end

        else begin
            if (counter >= 16'h100) begin
                counter <= 16'h0;
                mtime_o <= mtime_o + 1;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
