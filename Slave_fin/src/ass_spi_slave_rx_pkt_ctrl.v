module ass_spi_slave_rx_pkt_ctrl (
    input clk,
    input rstb,
    input byte_count_done,
    input rxempty,
    input txfull,
    input init,
    input request,
    input [7:0] rxrdata,
    input txre,

    output we,
    output byte_count_en,
    output [7:0] length_val,
    output txwe,
    output rxre,
    output load_addr,
    output inc_addr
    );

localparam [1:0] pkt_idle = 2'd0; // dev_addr
localparam [1:0] pkt_addr = 2'd1; // reg_addr -> load_addr
localparam [1:0] pkt_byte = 2'd2; // length   -> byte_count_en
localparam [1:0] pkt_data = 2'd3; // data     -> we, inc_addr

reg [1:0] pkt_state, pkt_state_n;

//-----------rxre delay----------------
reg rxre_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rxre_r <= 1'b0;
    end else if (init) begin
        rxre_r <= 1'b0;
    end else begin
        rxre_r <= rxre;
    end           
end

//-----------rxre delay----------------
wire rx_byte_req = (pkt_state == pkt_idle)
                || (pkt_state == pkt_addr)
                || (pkt_state == pkt_byte)
                || ((pkt_state == pkt_data) && !byte_count_done);
assign rxre = rx_byte_req && ~rxempty;

// ------------------------------------------------------------------
// State register
// ------------------------------------------------------------------
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        pkt_state <= pkt_idle;
    end else if (init) begin
        pkt_state <= pkt_idle;
    end else begin
        pkt_state <= pkt_state_n;
    end
end

// ------------------------------------------------------------------
// Next state
// ------------------------------------------------------------------
always @(*) begin
    pkt_state_n = pkt_state;
    case (pkt_state)
        pkt_idle: if (rxre_r)            pkt_state_n = pkt_addr;
        pkt_addr: if (rxre_r)            pkt_state_n = pkt_byte;
        pkt_byte: if (rxre_r)            pkt_state_n = pkt_data;
                  else if (request) pkt_state_n = pkt_data;
        pkt_data: pkt_state_n = pkt_data;
    endcase
end
// ------------------------------------------------------------------
// Output logic
// -----------------------------------------------------------------
assign we            = (pkt_state == pkt_data) && rxre_r && !byte_count_done;
assign txwe          = request && ~txfull;
assign byte_count_en = (pkt_state == pkt_byte) && rxre_r;
assign length_val    = rxrdata;
assign load_addr     = (pkt_state == pkt_addr) && rxre_r;
assign inc_addr      = (pkt_state == pkt_data) && rxre_r && !byte_count_done || request;


endmodule
