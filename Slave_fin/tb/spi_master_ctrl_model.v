`timescale 1ns / 10ps

module spi_master_ctrl_model (
  output wire sck,
  output reg  ssn,
  output reg  mosi,
  input  wire miso,
  input  wire cpol,
  input  wire cpha
);

parameter DEPTH = 128;
parameter CT = 76;

reg sclk;
reg sck_en;
reg [DEPTH*8-1:0] read_fifo;
reg [31:0] wdata;

always #(CT/2) sclk <= #3 ~sclk;

initial begin
  sclk      = 1'b0;
  sck_en    = 1'b0;
  mosi      = 1'b0;
  ssn       = 1'b1;
  wdata     = 32'h0;
  read_fifo = {(DEPTH*8){1'b0}};
end

assign sck = sck_en ? (cpol ? ~sclk : sclk) : cpol;

task start;
begin
    @(negedge sclk);
    ssn       = 1'b0;
    sck_en    = 1'b1;
    read_fifo = {(DEPTH*8){1'b0}};
end
endtask

task stop;
begin
    @(negedge sclk);
    sck_en = 1'b0;
    ssn    = 1'b1;
    mosi   = 1'b0;
end
endtask

task write_byte;
    input [7:0] data;
    reg [7:0] sreg;
    integer i;
begin
    sreg = data;

    if (!cpha) begin
        mosi = sreg[7];
    end

    for (i = 0; i < 8; i = i + 1) begin
        @(posedge sclk) begin
            if (cpha) begin
                mosi = sreg[7];
                sreg = {sreg[6:0], 1'b0};
            end else begin
                wdata <= {wdata[30:0], miso};
            end
        end

        @(negedge sclk) begin
            if (cpha) begin
                wdata <= {wdata[30:0], miso};
            end else begin
                sreg = {sreg[6:0], 1'b0};
                mosi = sreg[7];
            end
        end
    end

    $display("Write_byte: %02x", data);
    #1;
end
endtask

task read_byte;
    input [9:0] n;
    reg [7:0] sreg;
    integer i;
begin
    sreg = 8'h00;

    if (!cpha) begin
        mosi = 1'b0;
    end

    for (i = 0; i < 8; i = i + 1) begin
        @(posedge sclk) begin
            if (cpha) begin
                mosi = 1'b0;
            end else begin
                sreg = {sreg[6:0], miso};
            end
        end

        @(negedge sclk) begin
            if (cpha) begin
                sreg = {sreg[6:0], miso};
            end else begin
                mosi = 1'b0;
            end
        end
    end

    $display("read_byte: %02x", sreg);
    read_fifo = read_fifo ^ (sreg << (DEPTH-1-n)*8);
    #1;
end
endtask

task get_data;
    output [DEPTH*8-1:0] dout;
    input  [7:0] len;
    integer i;
begin
    dout = {(DEPTH*8){1'b0}};
    for (i = 0; i < len; i = i + 1) begin
        dout = dout ^ (read_fifo[(DEPTH-i-1)*8 +: 8] << ((DEPTH-i-1)*8));
    end
    #(1);
end
endtask

endmodule
