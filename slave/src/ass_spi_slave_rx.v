module ass_spi_slave_rx #(parameter [6:0] dev_adr = 7'h5a) (
    input clk,
    input rstb,
    input [1:0] ctrl0,
    input csn_i,
    input sck_i,
    input mosi_i,
    input [7:0] txwdata,

    output miso_o,
    output we,
    output [7:0] wdata,
    output [6:0] addr
);

// Synchronizer
wire sck_falling, sck_rising;
wire start_det, stop_det;
wire mosi_in;
ass_spi_slave_rx_sync u_sync (
    .clk        (clk),
    .rstb       (rstb),
    .csn_i      (csn_i),
    .sck_i      (sck_i),
    .mosi_i     (mosi_i),
    .sck_falling(sck_falling),
    .sck_rising (sck_rising),
    .start_det  (start_det),
    .stop_det   (stop_det),
    .mosi_in    (mosi_in)   
);

// 
wire count_clr, count_done, shift_en;
wire load_data, sample_en;
wire rxwe, txwe, rxre, txre;
wire rxfull, txempty;
wire rxempty, txfull;
wire [7:0] rxwdata;                             
wire init, request;                     
wire byte_count_done, byte_count_en;            
wire [7:0] length_val;
wire load_addr, inc_addr;   

ass_spi_slave_rx_rxctrl #(.dev_adr(dev_adr))
u_rxctrl(
    .clk        (clk),
    .rstb       (rstb),
    .start_det  (start_det),
    .stop_det   (stop_det),
    .sck_rising (sck_rising),
    .sck_falling(sck_falling),
    .rxfull     (rxfull),
    .txempty    (txempty),
    .rxwdata    (rxwdata),
    .ctrl0      (ctrl0),
    .count_done (count_done),


    .count_clr  (count_clr),
    .load_data  (load_data),
    .shift_en   (shift_en),
    .rxwe       (rxwe),
    .txre       (txre),
    .sample_en  (sample_en),
    .init   (init),
    .request(request)
    );

//----------bit counter------------------
ass_spi_slave_rx_bit_counter u_cnt (
    .clk        (clk),
    .rstb       (rstb),
    .count_clr  (count_clr),
    .shift_en   (shift_en),
    .count_done (count_done)
);

//------RX FIFO---------------
wire [7:0] rxrdata;
generic_fifo_dc #(
    .dw(8),
    .aw(1)
) u_rx_fifo (
    .wr_clk (clk),
    .rd_clk (clk),
    .rst    (rstb),
    .clr    (1'b0),
    .din    (rxwdata),
    .we     (rxwe),
    .dout   (rxrdata),
    .re     (rxre),
    .empty  (rxempty),
    .full   (rxfull),
    .full_n (),
    .empty_n(),
    .level  ()
);

//--------TX FIFO---------------
wire [7:0] txrdata;
generic_fifo_dc #(
    .dw(8),
    .aw(1)
) u_tx_fifo (
    .wr_clk (clk),
    .rd_clk (clk),
    .rst    (rstb),
    .clr    (1'b0),
    .din    (txwdata), //txwdata
    .we     (txwe),
    .dout   (txrdata),
    .re     (txre),
    .empty  (txempty),
    .full   (txfull),
    .full_n (),
    .empty_n(),
    .level  ()
);

//--------Deserializer------------------------
ass_spi_slave_rx_deserializer u_rx_deserial (
    .clk        (clk),
    .rstb       (rstb),
    .load_data  (load_data),
    .shift_en   (shift_en),
    .sample_en  (sample_en),
    .txrdata    (txrdata),
    .mosi_in    (mosi_in),
    .rxwdata    (rxwdata),
    .miso_o     (miso_o)
);

//-------------Addr register---------------------
ass_spi_slave_rx_addr u_addr (
    .clk      (clk),
    .rstb     (rstb),
    .load_addr(load_addr),
    .inc_addr (inc_addr), 
    .rxrdata  (rxrdata[6:0]),  // rxwdata -> rxrdata
    .addr     (addr)
);

//-----------Packet FSM--------------------------
ass_spi_slave_rx_pkt_ctrl u_pkt_ctrl (
    .clk            (clk),
    .rstb           (rstb),
    .byte_count_done(byte_count_done),
    .rxempty        (rxempty),
    .txfull         (txfull),
    .init       (init),
    .request    (request),
    .rxrdata        (rxrdata),
    .txre       (txre),

    .we             (we),
    .byte_count_en  (byte_count_en),
    .length_val     (length_val),
    .rxre           (rxre),
    .txwe           (txwe),
    .load_addr      (load_addr),
    .inc_addr       (inc_addr)
);


//---------byte_counter-------------------------
ass_spi_slave_rx_byte_counter u_byte_counter (
    .clk            (clk),
    .rstb           (rstb),
    .byte_count_en  (byte_count_en),
    .we             (we),
    .length_val     (length_val),
    .byte_count_done(byte_count_done)
);

assign wdata = rxrdata;

endmodule