`timescale 1ns / 1ps

module tb_spi_rx_user_variant ();

reg clk;
reg reset_n;

initial clk = 0;
always #5 clk = ~clk;

wire sck;
wire csn;
wire mosi;
wire miso;
reg cpol;
reg cpha;
wire miso_to_master;
wire sck_to_slave;
wire sck_mode00;
wire sck_mode01;
wire sck_mode10;
wire sck_mode11;

spi_master_model u_spi_master_model (
  .sck    (sck    ),
  .ssn    (csn    ),
  .mosi   (mosi   ),
  .miso   (miso_to_master)
);

parameter [6:0] dev_adr = 7'h74;

reg [128*8-1:0] read_data;

task run_test;
begin
    #50;
    u_spi_master_model.start;
    u_spi_master_model.write_byte({dev_adr, 1'b0});
    u_spi_master_model.write_byte(8'h0a);
    u_spi_master_model.write_byte(8'h08);
    u_spi_master_model.write_byte(8'h51);
    u_spi_master_model.write_byte(8'h62);
    u_spi_master_model.write_byte(8'h73);
    u_spi_master_model.write_byte(8'h84);
    u_spi_master_model.write_byte(8'h95);
    u_spi_master_model.write_byte(8'ha6);
    u_spi_master_model.write_byte(8'hb7);
    u_spi_master_model.write_byte(8'hc8);
    u_spi_master_model.stop;

    #100;
    u_spi_master_model.start;
    u_spi_master_model.write_byte({dev_adr, 1'b0});
    u_spi_master_model.write_byte(8'h10);
    u_spi_master_model.write_byte(8'h04);
    u_spi_master_model.write_byte(8'h13);
    u_spi_master_model.write_byte(8'h25);
    u_spi_master_model.write_byte(8'h47);
    u_spi_master_model.write_byte(8'h69);
    u_spi_master_model.write_byte(8'hAA);
    u_spi_master_model.write_byte(8'hAA);
    u_spi_master_model.stop;

    #100;
    u_spi_master_model.start;
    u_spi_master_model.write_byte({dev_adr, 1'b1});
    u_spi_master_model.write_byte(8'h0C);
    u_spi_master_model.write_byte(8'h08);
    u_spi_master_model.read_byte(0);
    u_spi_master_model.read_byte(1);
    u_spi_master_model.read_byte(2);
    u_spi_master_model.read_byte(3);
    u_spi_master_model.read_byte(4);
    u_spi_master_model.read_byte(5);
    u_spi_master_model.read_byte(6);
    u_spi_master_model.read_byte(7);
    u_spi_master_model.stop;
    u_spi_master_model.get_data(read_data, 8'd8);

    #(1000);
    u_spi_master_model.start;
    u_spi_master_model.write_byte({dev_adr, 1'b0});
    u_spi_master_model.write_byte(8'h20);
    u_spi_master_model.write_byte(8'h08);
    u_spi_master_model.write_byte(read_data[127*8 +: 8] + 1'b1);
    u_spi_master_model.write_byte(read_data[126*8 +: 8] + 1'b1);
    u_spi_master_model.write_byte(read_data[125*8 +: 8] + 1'b1);
    u_spi_master_model.write_byte(read_data[124*8 +: 8] + 1'b1);
    u_spi_master_model.write_byte(read_data[123*8 +: 8] + 1'b1);
    u_spi_master_model.write_byte(read_data[122*8 +: 8] + 1'b1);
    u_spi_master_model.write_byte(read_data[121*8 +: 8] + 1'b1);
    u_spi_master_model.write_byte(read_data[120*8 +: 8] + 1'b1);
    u_spi_master_model.stop;
end
endtask

wire [1:0] ctrl0;

assign ctrl0 = {cpha, cpol};
assign sck_mode00 = u_spi_master_model.ssn_t ?  u_spi_master_model.sclk : 1'b0;
assign sck_mode01 = u_spi_master_model.ssn_t ? ~u_spi_master_model.sclk : 1'b1;
assign sck_mode10 = csn ? 1'b0 : ~u_spi_master_model.sclk;
assign sck_mode11 = csn ? 1'b1 :  u_spi_master_model.sclk;
assign sck_to_slave = (ctrl0 == 2'b00) ? sck_mode00 :
                      (ctrl0 == 2'b01) ? sck_mode01 :
                      (ctrl0 == 2'b10) ? sck_mode10 :
                                         sck_mode11;
assign miso_to_master = miso;

ass_spi_slave #(.dev_adr(dev_adr)) dut (
    .clk    (clk          ),
    .rstb   (reset_n      ),
    .ctrl0  (ctrl0        ),
    .csn_i  (csn          ),
    .sck_i  (sck_to_slave ),
    .mosi_i (mosi         ),
    .miso_o (miso         )
);

initial begin
    cpol    = 1'b0;
    cpha    = 1'b0;
    reset_n = 1'b0;
    repeat(10) @(negedge clk);
    reset_n = 1'b1;
    $display("Running ctrl0=%b (CPOL=%0b CPHA=%0b)", ctrl0, cpol, cpha);
    run_test;
    #200;

    cpol    = 1'b1;
    cpha    = 1'b0;
    reset_n = 1'b0;
    repeat(10) @(negedge clk);
    reset_n = 1'b1;
    $display("Running ctrl0=%b (CPOL=%0b CPHA=%0b)", ctrl0, cpol, cpha);
    run_test;
    #200;

    cpol    = 1'b0;
    cpha    = 1'b1;
    reset_n = 1'b0;
    repeat(10) @(negedge clk);
    reset_n = 1'b1;
    $display("Running ctrl0=%b (CPOL=%0b CPHA=%0b)", ctrl0, cpol, cpha);
    run_test;
    #200;

    cpol    = 1'b1;
    cpha    = 1'b1;
    reset_n = 1'b0;
    repeat(10) @(negedge clk);
    reset_n = 1'b1;
    $display("Running ctrl0=%b (CPOL=%0b CPHA=%0b)", ctrl0, cpol, cpha);
    run_test;
    #200;

end

endmodule
