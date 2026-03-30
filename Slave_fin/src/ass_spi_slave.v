
`timescale 1ns/10ps

module ass_spi_slave #(parameter [6:0] dev_adr = 7'h5a)(
  input       clk    ,
  input       rstb   ,
  input [1:0] ctrl0  ,
  input       csn_i  ,
  input       sck_i  ,
  input       mosi_i ,
  output      miso_o
);

// ----------------------------------------------------------------------------
// Control Register Description
// ----------------------------------------------------------------------------
// ctrl0  : [1:0] {CPHA: clock_phase, CPOL: clock_polarity}


// Write a SPI Slave RTL Code ...
wire we;
wire [6:0] addr;
wire [7:0] wdata, txwdata;

ass_spi_slave_rx  #(.dev_adr(dev_adr)) 
u_rx(
  .clk      (clk),
  .rstb     (rstb),
  .ctrl0    (ctrl0),
  .csn_i    (csn_i),
  .sck_i    (sck_i),
  .mosi_i   (mosi_i),
  .txwdata    (txwdata),


  .miso_o   (miso_o),
  .we       (we),
  .wdata    (wdata),
  .addr     (addr)
);


ass_spi_slave_rf u_rf(
  .clk      (clk),
  .rstb     (rstb),
  .addr     (addr),
  .we       (we),
  .wdata    (wdata),
  .txwdata    (txwdata)
);

endmodule

