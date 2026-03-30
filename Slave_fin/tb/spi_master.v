
`timescale 1ns / 10ps

module spi_master_model (
  output wire sck ,
  output reg  ssn ,
  output reg  mosi,
  input  wire miso
);

// --- Initialize FIFO -----------------
parameter DEPTH = 128;

parameter CT = 76;  // 13MHz

reg sclk ;
always #(CT/2) sclk <= #3 ~sclk ;

reg [DEPTH*8-1:0] read_fifo ;   // read data fifo size (256bytes)
reg [31:0] wdata ;  // for test

reg ssn_t, ssn_t2 ;
reg rst;

initial begin
	sclk   = 0;
  mosi   = 0 ;
  ssn    = 1 ;
  ssn_t  = 0 ;
  ssn_t2 = 0 ;
  wdata  = 0 ;
  read_fifo  = 0 ;
  rst    = 0 ;
  repeat(1) @(posedge sck);
  rst    = 1 ;
end // initial

assign sck = sclk & ssn_t | ssn_t2;

reg [2:0] sck_cnt;
always @(posedge sck or negedge rst)
begin
	if (~rst) begin
		sck_cnt <= 3'b0;
	end
	else begin
		if (ssn_t) sck_cnt <= sck_cnt + 1'b1;
	end
end // always

task start;
begin
    @(posedge sclk) ssn = 0;
    read_fifo = 0;
end
endtask

task stop;
begin
    @(negedge sclk) ssn_t = 0;
    @(negedge sclk) ssn = 1;
end
endtask

task write_byte;
	input [7:0] data;
	reg [7:0] sreg;
begin

	sreg = data;

	repeat(8) begin
		@(negedge sclk) begin
			ssn_t = 1;
			mosi = sreg[7];
			sreg = sreg <<1;
		end

		@(posedge sclk) begin
			wdata <= {wdata[30:0], miso};
		end
	end //

	$display("Write_byte: %02x", data);
	#1;

end // write_byte
endtask

task read_byte;
	input [9:0] n;
	reg [7:0] sreg;
begin

  @(negedge sclk) mosi = 1'b0; //mosi = 1'bx

	repeat(8) @(posedge sclk) begin
		sreg = {sreg[6:0], miso};
	end

	$display("read_byte: %02x", sreg);

	read_fifo = read_fifo ^ (sreg<<(DEPTH-1-n)*8);

	#1;

end // read_byte
endtask

task get_data;
	output [DEPTH*8-1:0] dout;
	input  [7:0]  len;
	reg [DEPTH*8-1:0] dat;
	integer i;
begin
	dout = {(DEPTH*8){1'b0}};
	for (i = 0; i < len; i = i + 1) begin
		dout = dout ^ (read_fifo[(DEPTH-i-1)*8 +: 8] << ((DEPTH-i-1)*8));
	end
	//read_fifo = read_fifo << len*8;
	//dout = dat;
	#(1);
end
endtask // get_data



endmodule
