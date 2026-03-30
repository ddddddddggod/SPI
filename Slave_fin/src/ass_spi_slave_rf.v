module ass_spi_slave_rf(
	input clk,
	input rstb,
	input we,
	input [6:0] addr,
	input [7:0] wdata,
	output [7:0] txwdata
);

reg [7:0] mem [0:127]; // 128x8

//Write
integer i;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        for (i=0; i<128; i=i+1) mem[i] <= 8'h00;
    end else if (we) begin  //we=1 
        mem[addr] <= wdata;
    end
end

//Read
assign txwdata = mem[addr];

endmodule