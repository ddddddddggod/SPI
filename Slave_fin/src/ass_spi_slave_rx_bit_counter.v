module ass_spi_slave_rx_bit_counter (
	input clk,
	input rstb,
	input count_clr,
	input shift_en,

	output count_done
);

	reg [2:0] count_reg;
	always @(posedge clk or negedge rstb) begin
		if (!rstb) begin
			count_reg <= 3'd0;
		end else if (count_clr) begin
		    count_reg <= 3'd0;
		end else if (shift_en) begin
		    count_reg <= count_reg + 1'b1;
		end
	end

	assign count_done = (count_reg == 3'd7);

endmodule