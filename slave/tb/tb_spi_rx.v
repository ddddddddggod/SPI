
`timescale 1ns / 1ps

module tb_spi_rx ();

//******************************************************************
// Clock & Reset
//******************************************************************

reg clk;
reg reset_n;

initial clk = 0;
always #5 clk = ~clk;

initial begin
	reset_n = 1'b0;
	repeat(10) @(negedge clk);
	reset_n = 1'b1;
end //


//******************************************************************
// SPI Master Model
//******************************************************************
wire sck;
wire csn;
wire mosi;
wire miso;
spi_master_model u_spi_master_model (
  .sck    (sck    ),
  .ssn    (csn    ),
  .mosi   (mosi   ),
  .miso   (miso   )
);

//******************************************************************
// Run an SPI master model
//******************************************************************
parameter [6:0] dev_adr = 7'h74;

reg [128*8-1:0] read_data;
initial begin
	#50;
	// Write Data Set 1
	u_spi_master_model.start; // start
	u_spi_master_model.write_byte({dev_adr, 1'b0}); // (start with WRITE)
	u_spi_master_model.write_byte(8'h0a); // (write addr  )
	u_spi_master_model.write_byte(8'h08); // (write length)
	u_spi_master_model.write_byte(8'h51); // (write data @ addr = 0x0a)
	u_spi_master_model.write_byte(8'h62); // (write data @ addr = 0x0b)
	u_spi_master_model.write_byte(8'h73); // (write data @ addr = 0x0c)
	u_spi_master_model.write_byte(8'h84); // (write data @ addr = 0x0d)
	u_spi_master_model.write_byte(8'h95); // (write data @ addr = 0x0e)
	u_spi_master_model.write_byte(8'ha6); // (write data @ addr = 0x0f)
	u_spi_master_model.write_byte(8'hb7); // (write data @ addr = 0x10)
	u_spi_master_model.write_byte(8'hc8); // (write data @ addr = 0x11)
	u_spi_master_model.stop;  // stop

	#100
	// Write Data Set 1
	u_spi_master_model.start; // start
	u_spi_master_model.write_byte({dev_adr, 1'b0} ); // (start with WRITE)
	u_spi_master_model.write_byte(8'h10); // (write addr  )
	u_spi_master_model.write_byte(8'h04); // (write length)
	u_spi_master_model.write_byte(8'h13); // (write data @ addr = 0x10)
	u_spi_master_model.write_byte(8'h25); // (write data @ addr = 0x11)
	u_spi_master_model.write_byte(8'h47); // (write data @ addr = 0x12)
	u_spi_master_model.write_byte(8'h69); // (write data @ addr = 0x13)
	u_spi_master_model.write_byte(8'hAA); // (write data @ addr = 0x14)
	u_spi_master_model.write_byte(8'hAA); // (write data @ addr = 0x15)
	u_spi_master_model.stop;  // stop

	#100;
	// Read Data Set
	u_spi_master_model.start; // start
	u_spi_master_model.write_byte({dev_adr, 1'b1} ); // (start with READ)
	u_spi_master_model.write_byte(8'h0C); // (write addr  )
	u_spi_master_model.write_byte(8'h08); // (write length)
	u_spi_master_model.read_byte(0);      // (read data @ addr = 0x0C)
	u_spi_master_model.read_byte(1);      // (read data @ addr = 0x0D)
	u_spi_master_model.read_byte(2);      // (read data @ addr = 0x0E)
	u_spi_master_model.read_byte(3);      // (read data @ addr = 0x0F)
	u_spi_master_model.read_byte(4);      // (read data @ addr = 0x10)
	u_spi_master_model.read_byte(5);      // (read data @ addr = 0x11)
	u_spi_master_model.read_byte(6);      // (read data @ addr = 0x12)
	u_spi_master_model.read_byte(7);      // (read data @ addr = 0x13)
	u_spi_master_model.stop;  // stop
	u_spi_master_model.get_data(read_data, 8'd8);

	#(1000)
	// Write Data
	u_spi_master_model.start; // start
	u_spi_master_model.write_byte({dev_adr, 1'b0} ); // (start with WRITE)
	u_spi_master_model.write_byte(8'h20); // (write addr  )
	u_spi_master_model.write_byte(8'h08); // (write length)
	u_spi_master_model.write_byte(read_data[127*8 +: 8] + 1'b1); // (write data @ addr = 0x30)
	u_spi_master_model.write_byte(read_data[126*8 +: 8] + 1'b1); // (write data @ addr = 0x31)
	u_spi_master_model.write_byte(read_data[125*8 +: 8] + 1'b1); // (write data @ addr = 0x32)
	u_spi_master_model.write_byte(read_data[124*8 +: 8] + 1'b1); // (write data @ addr = 0x33)
	u_spi_master_model.write_byte(read_data[123*8 +: 8] + 1'b1); // (write data @ addr = 0x34)
	u_spi_master_model.write_byte(read_data[122*8 +: 8] + 1'b1); // (write data @ addr = 0x35)
	u_spi_master_model.write_byte(read_data[121*8 +: 8] + 1'b1); // (write data @ addr = 0x36)
	u_spi_master_model.write_byte(read_data[120*8 +: 8] + 1'b1); // (write data @ addr = 0x37)
	u_spi_master_model.stop;  // stop

end //

//******************************************************************
// Control Register Setting
//******************************************************************
wire [1:0] ctrl0;
reg cpol;
reg cpha;
initial begin
  cpol      = 1'b0;
  cpha      = 1'b0;
end // initial

assign ctrl0 = {cpha, cpol};

//******************************************************************
// Desing under Testing:  SPI Slave RTL
//******************************************************************
ass_spi_slave #(.dev_adr(dev_adr)) dut (

	.clk    (clk    ),
	.rstb   (reset_n),
	.ctrl0  (ctrl0  ),
  .csn_i  (csn    ),
  .sck_i  (sck    ),
  .mosi_i (mosi   ),
  .miso_o (miso   )
);


endmodule
