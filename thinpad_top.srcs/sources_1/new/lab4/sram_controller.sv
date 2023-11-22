module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [SRAM_BYTES-1:0] sram_be_n
);

	// state machine
	typedef enum logic [2:0] {
		ST_IDLE,
		ST_READ_1,
		ST_READ_2,
		ST_WRITE_1,
		ST_WRITE_2,
		ST_WRITE_3,
		ST_DONE
	} state_t;
	state_t state;

	wire [31:0] sram_data_i_comb;
	reg [31:0] sram_data_o_comb;
	reg sram_data_t_comb;
	assign sram_data = sram_data_t_comb ? 32'bz : sram_data_o_comb;
	assign sram_data_i_comb = sram_data;

  	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			sram_ce_n <= 1'b1;
			sram_oe_n <= 1'b1;
			sram_we_n <= 1'b1;
			wb_ack_o <= 1'b0;
			state <= ST_IDLE;
		end
    	else begin
			case (state)
				ST_IDLE: begin
					// wait for valid wishbone request
					if (wb_cyc_i && wb_stb_i) begin
						sram_ce_n <= 1'b0;
						sram_we_n <= 1'b1;
						sram_be_n <= ~wb_sel_i;
						sram_addr <= (wb_adr_i >> 2);
						if (wb_we_i) begin // write
							sram_oe_n <= 1'b1;
							sram_data_t_comb <= 1'b0;
							sram_data_o_comb <= wb_dat_i;
							state <= ST_WRITE_1;
						end else begin // read
							sram_oe_n <= 1'b0;
							sram_data_t_comb <= 1'b1;
							state <= ST_READ_1;
						end
					end
				end

				ST_READ_1: begin
					// wait for read data to be ready
					state <= ST_READ_2;
				end

				ST_READ_2: begin
					// read data from sram and send to wishbone
					wb_dat_o <= sram_data_i_comb;
					sram_ce_n <= 1'b1;
					sram_oe_n <= 1'b1;
					wb_ack_o <= 1'b1;
					state <= ST_DONE;
				end

				ST_WRITE_1: begin
					// wait for write data to be ready
					sram_we_n <= 1'b0;
					state <= ST_WRITE_2;
				end

				ST_WRITE_2: begin
					// compute correct write data
					sram_we_n <= 1'b1;
					state <= ST_WRITE_3;
				end

				ST_WRITE_3: begin
					// write data to sram
					sram_ce_n <= 1'b1;
					wb_ack_o <= 1'b1;
					state <= ST_DONE;
				end

				ST_DONE: begin
					// wait for wishbone to deassert
					wb_ack_o <= 1'b0;
					state <= ST_IDLE;
				end
			endcase
    	end
  	end

endmodule
