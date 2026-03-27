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

localparam [1:0] st_idle   = 2'd0; // 
localparam [1:0] st_rx_dev = 2'd1; // device addr + R/W
localparam [1:0] st_rx     = 2'd2; // write: reg_addr, length, data
localparam [1:0] st_tx     = 2'd3; // read:  reg_addr, length, data

reg [1:0] state, state_n;

wire addr_match = (rxwdata[7:1] == dev_adr);
assign init = start_det || stop_det;

wire byte_done = count_done && shift_en;
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
wire active = (state == st_rx_dev) || (state == st_rx) || (state == st_tx);

assign rxwe      = active && byte_done_r && ~rxfull;
assign count_clr = (state == st_idle) || init || byte_done_r;

// txre delay : FIFO pop
reg txre_o;
reg load_data_o;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        txre_o <= 1'b0;
    end else if (init) begin
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
    end else if (init) begin
        load_data_o <= 1'b0;
    end else begin
        load_data_o <= txre;
    end
end
assign load_data = load_data_o;

// ctrl = {cpha, cpol}
always @(*) begin
    case (ctrl0)
        2'b00: begin
            sample_en = active && sck_rising;
            shift_en  = active && sck_falling;
        end
        2'b01: begin
            sample_en = active && sck_falling;
            shift_en  = active && sck_rising;
        end
        2'b10: begin
            sample_en = active && sck_falling;
            shift_en  = active && sck_rising;
        end
        2'b11: begin
            sample_en = active && sck_rising;
            shift_en  = active && sck_falling;
        end
        default: begin
            sample_en = active && sck_rising;
            shift_en  = active && sck_falling;
        end
    endcase
end

endmodule