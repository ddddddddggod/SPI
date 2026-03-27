module ass_spi_slave_rx_deserializer (
	input clk,
	input rstb,
	input load_data,
    input shift_en,
	input sample_en,
	input [7:0] txrdata,
    input mosi_in,

	output [7:0] rxwdata,
	output miso_o
);
    reg mosi_sampled;
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            mosi_sampled <= 1'b0;
        end else if (sample_en) begin
            mosi_sampled <= mosi_in;
        end
    end
    
    // ── TX shift register (read path) ────────────────
    reg [7:0] tx_shift_reg;
    always @(posedge clk or negedge rstb) begin
        if (!rstb)      tx_shift_reg <= 8'h00;
        else if (load_data)  tx_shift_reg <= txrdata;  
        else if (shift_en) tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
    end

    // ── RX shift register (write path) ───────────────
    reg [7:0] rx_shift_reg;
    always @(posedge clk or negedge rstb) begin
        if (!rstb)          rx_shift_reg <= 8'h00;
        else if (shift_en)  rx_shift_reg <= {rx_shift_reg[6:0], mosi_sampled};
    end

    assign rxwdata = rx_shift_reg;
    assign miso_o  = tx_shift_reg[7];

endmodule


