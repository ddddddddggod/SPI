module ass_spi_slave_rx_sync(
	input clk,
	input rstb,
	input csn_i, 
	input sck_i,
	input mosi_i,

	output sck_falling,
	output sck_rising,
	output start_det,
	output stop_det,
	output mosi_in
);

//2-level synchronization
reg [1:0] csn_sync, sck_sync, mosi_sync;
always @(posedge clk or negedge rstb) begin
  if (!rstb) begin
    sck_sync <= 2'b11;  // ctrl마다 다른디
    csn_sync <= 2'b11; //default high
    mosi_sync <= 2'b11; //default high
  end else begin
    sck_sync <= {sck_sync[0], sck_i};
    csn_sync <= {csn_sync[0], csn_i};
    mosi_sync <= {mosi_sync[0], mosi_i};
  end
end

// edge detect
assign sck_rising  = (sck_sync[1:0] == 2'b01);
assign sck_falling = (sck_sync[1:0] == 2'b10);
assign csn_rising = (csn_sync[1:0] == 2'b01);
assign csn_falling = (csn_sync[1:0] == 2'b10);

//stable data (mosi)
assign mosi_in = mosi_sync[1];

// START/STOP detect
assign start_det = csn_falling;  
assign stop_det  = csn_rising;

endmodule