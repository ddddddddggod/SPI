module ass_spi_slave_rx_deserializer (
    input clk,
    input rstb,
    input cpha,
    input load_data,
    input shift_en,
    input sample_en,
    input [7:0] txrdata,
    input mosi_in,

    output [7:0] rxwdata,
    output miso_o
);

    reg mosi_sampled;
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            mosi_sampled <= 1'b0;
        end else if (sample_en) begin
            mosi_sampled <= mosi_in;
        end
    end
    //---tx-----------------------
    reg [7:0] tx_shift_reg;
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            tx_shift_reg <= 8'h00;
        end else if (load_data) begin
            tx_shift_reg <= txrdata;
        end else if (shift_en) begin
            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
        end
    end

    //-----rx---------------------
    wire       rx_shift_en  = cpha ? sample_en : shift_en;
    wire       rx_shift_bit = cpha ? mosi_in : mosi_sampled; //cpha=1 => already stable

    reg [7:0]  rx_shift_reg;
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            rx_shift_reg <= 8'h00;
        end else if (rx_shift_en) begin
            rx_shift_reg <= {rx_shift_reg[6:0], rx_shift_bit};
        end
    end

    assign rxwdata = rx_shift_reg;
    assign miso_o  = tx_shift_reg[7];

endmodule
