module ass_spi_slave_rx_rxctrl #(parameter [6:0] dev_adr = 7'h5a)(
    input clk,
    input rstb,
    input start_det,
    input stop_det,
    input sck_rising,
    input sck_falling,
    input rxfull,
    input txempty,
    input [7:0] rxwdata,
    input [1:0] ctrl0,
    input count_done,

    output count_clr,
    output load_data,
    output reg shift_en,
    output rxwe,
    output txre,
    output reg sample_en,
    output init,
    output request
);

localparam [1:0] st_idle   = 2'd0;
localparam [1:0] st_rx_dev = 2'd1;
localparam [1:0] st_rx     = 2'd2;
localparam [1:0] st_tx     = 2'd3;

reg [1:0] state, state_n;
reg [2:0] stop_det_dly;

wire addr_match = (rxwdata[7:1] == dev_adr);
wire ctrl_init = start_det || stop_det;
assign init = start_det || stop_det_dly[2];

always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        stop_det_dly <= 3'b000;
    end else if (start_det) begin
        stop_det_dly <= 3'b000;
    end else begin
        stop_det_dly <= {stop_det_dly[1:0], stop_det};
    end
end

//ctrl
wire bit_done_en = ctrl0[1] ? sample_en : shift_en;
wire byte_done = count_done && bit_done_en;
reg byte_done_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        byte_done_r <= 1'b0;
    end else begin
        byte_done_r <= byte_done;
    end
end

wire first_read   = (state == st_rx_dev) && byte_done_r && addr_match && rxwdata[0];
wire seq_read_req = (state == st_tx) && count_done && sample_en;
assign request = first_read || seq_read_req;

//-------------------------------------
// Current state
//-------------------------------------
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        state <= st_idle;
    end else if (stop_det) begin
        state <= st_idle;
    end else if (start_det) begin
        state <= st_rx_dev;
    end else begin
        state <= state_n;
    end
end

//------------------------------------------------------
// Next state
//------------------------------------------------------
always @(*) begin
    state_n = state;
    case (state)
    st_idle:   state_n = st_idle;
    st_rx_dev: if (byte_done_r)
                   state_n = addr_match ? (rxwdata[0] ? st_tx : st_rx) : st_idle;
    st_rx: state_n = st_rx;
    st_tx: state_n = st_tx;
    endcase
end

//-------------------------------------------------
// Output logic
//-------------------------------------------------

assign rxwe      = byte_done_r && ~rxfull;
assign count_clr = (state == st_idle) || ctrl_init || byte_done_r;

// txre delay : FIFO pop
reg txre_o;
reg load_data_o;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        txre_o <= 1'b0;
    end else if (ctrl_init) begin
        txre_o <= 1'b0;
    end else if (txre) begin
        txre_o <= 1'b0;
    end else if (request) begin
        txre_o <= 1'b1;
    end
end
assign txre = txre_o && !txempty;

always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        load_data_o <= 1'b0;
    end else if (ctrl_init) begin
        load_data_o <= 1'b0;
    end else begin
        load_data_o <= txre;
    end
end
assign load_data = load_data_o;

//-------------------------------------
// sample_en / shift_en
//-------------------------------------
wire first_edge = (state == st_rx_dev) || (state == st_rx) || (state == st_tx);

reg skip_first;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        skip_first <= 1'b0;
    end else if (ctrl_init || byte_done_r) begin
        skip_first <= 1'b0;
    end else if (first_edge && !skip_first) begin
        if (ctrl0 == 2'b10 && sck_rising)  skip_first <= 1'b1;
        if (ctrl0 == 2'b11 && sck_falling) skip_first <= 1'b1;
    end
end

always @(*) begin
    case (ctrl0)
        2'b00: begin  // 1st edge: rising=sample, falling=shift
            sample_en = first_edge && sck_rising;
            shift_en  = first_edge && sck_falling;
        end
        2'b01: begin  // 1st edge: falling=sample, rising=shift
            sample_en = first_edge && sck_falling;
            shift_en  = first_edge && sck_rising;
        end
        2'b10: begin
            shift_en  = first_edge && sck_rising;           
            sample_en = first_edge && skip_first && sck_falling; 
        end
        2'b11: begin
            shift_en  = first_edge && sck_falling;          
            sample_en = first_edge && skip_first && sck_rising;  
        end
        default: begin
            sample_en = first_edge && sck_rising;
            shift_en  = first_edge && sck_falling;
        end
    endcase
end

endmodule
