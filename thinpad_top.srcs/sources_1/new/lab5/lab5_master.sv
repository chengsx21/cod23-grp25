module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire [ADDR_WIDTH-1:0] addr_i,

    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

	typedef enum logic [3:0] {
		ST_IDLE,
		ST_READ_WAIT_ACTION,
		ST_READ_WAIT_CHECK,
		ST_READ_DATA_ACTION,
		ST_READ_DATA_DONE,
		ST_WRITE_SRAM_ACTION,
		ST_WRITE_SRAM_DONE,
		ST_WRITE_WAIT_ACTION,
		ST_WRITE_WAIT_CHECK,
		ST_WRITE_DATA_ACTION,
		ST_WRITE_DATA_DONE
	} state_t;
	state_t state;

	// used for counting
	logic [3:0] cnt;
	// used for storing data
	logic [DATA_WIDTH-1:0] data;
	// used for storing address
	logic [ADDR_WIDTH-1:0] addr;

	assign wb_cyc_o = wb_stb_o;

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			wb_stb_o <= 0;
			wb_we_o <= 0;

			wb_adr_o <= 0;
			wb_dat_o <= 0;
			wb_sel_o <= 4'b0000;

			cnt <= 0;
			addr <= addr_i;
			data <= 0;
			state <= ST_IDLE;
		end else begin

			case (state)
				ST_IDLE: begin
				// read uart status => check if there is data
					if (cnt < 10) begin
						cnt <= cnt + 1;
						wb_stb_o <= 1;
						wb_we_o <= 0;

						wb_adr_o <= 32'h10000005;
						wb_sel_o <= 4'b0010;
						state <= ST_READ_WAIT_ACTION;
					end
				end

				ST_READ_WAIT_ACTION: begin
					// wait for ack
					if (wb_ack_i) begin
						wb_stb_o <= 0;
						state <= ST_READ_WAIT_CHECK;
					end
				end

				ST_READ_WAIT_CHECK: begin
					// check if there is data
					wb_stb_o <= 1;
					if (wb_dat_i[8]) begin
						wb_adr_o <= 32'h10000000;
						wb_sel_o <= 4'b0001;
						state <= ST_READ_DATA_ACTION;
					end else begin
						state <= ST_READ_WAIT_ACTION;
					end
				end

				ST_READ_DATA_ACTION: begin
					// read data from uart
					if (wb_ack_i) begin
						wb_stb_o <= 0;

						data <= wb_dat_i;
						state <= ST_READ_DATA_DONE;
					end
				end
				
				ST_READ_DATA_DONE: begin
					// write data to sram
					//! note that `wb_dat_o and `wb_sel_o should be shifted
					wb_stb_o <= 1;
					wb_we_o <= 1;

					wb_adr_o <= addr;
					addr <= addr + 4;
					wb_dat_o <= (data << ((addr & 2'b11) << 3));
					wb_sel_o <= (4'b0001 << (addr & 2'b11));
					state <= ST_WRITE_SRAM_ACTION;
				end

				ST_WRITE_SRAM_ACTION: begin
					// wait for ack
					if (wb_ack_i) begin
						wb_stb_o <= 0;
						state <= ST_WRITE_SRAM_DONE;
					end
				end

				ST_WRITE_SRAM_DONE: begin
					// read uart status => check if it is ready
					wb_stb_o <= 1;
					wb_we_o <= 0;

					wb_adr_o <= 32'h10000005;
					wb_sel_o <= 4'b0010;
					state <= ST_WRITE_WAIT_ACTION;
				end

				ST_WRITE_WAIT_ACTION: begin
					// wait for ack
					if (wb_ack_i) begin
						wb_stb_o <= 0;
						state <= ST_WRITE_WAIT_CHECK;
					end
				end

				ST_WRITE_WAIT_CHECK: begin
					// check if it is ready
					wb_stb_o <= 1;
					if (wb_dat_i[13]) begin
						wb_we_o <= 1;

						wb_adr_o <= 32'h10000000;
						wb_dat_o <= data;
						wb_sel_o <= 4'b0001;
						state <= ST_WRITE_DATA_ACTION;
					end else begin
						state <= ST_WRITE_WAIT_ACTION;
					end
				end

				ST_WRITE_DATA_ACTION: begin
					// write data to uart
					if (wb_ack_i) begin
						wb_stb_o <= 0;
						state <= ST_WRITE_DATA_DONE;
					end
					end

					ST_WRITE_DATA_DONE: begin
					state <= ST_IDLE;
				end
			endcase
    	end
  	end
endmodule
