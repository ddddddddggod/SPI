module ass_spi_slave_rx_byte_counter (
	input clk,
	input rstb,
	input byte_count_en,
	input we,
	input [7:0] length_val,

	output byte_count_done
);


    reg [7:0] cnt_reg;

    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            cnt_reg <= 8'h00;
        end else if (byte_count_en) begin
            cnt_reg <= length_val;
        end else if (we) begin
            cnt_reg <= cnt_reg - 1'b1;
        end
    end

    assign byte_count_done = (cnt_reg == 8'h00);

endmodule

