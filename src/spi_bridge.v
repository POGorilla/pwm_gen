`timescale 1ns/1ns

module spi_bridge (
    input wire clk,
    input wire rst_n,

    input wire sclk,
    input wire cs_n,
    input wire mosi,
    output reg miso,

    output reg byte_sync,
    output reg [7:0] data_in,
    input wire [7:0] data_out
);

    // registre pentru receptia datelor pe MOSI
    reg [7:0] rx_shift_s;
    reg [2:0] rx_cnt_s;
    reg [7:0] rx_byte_s;
    reg rx_tgl_s;

    // citire date MOSI pe front crescator (CPHA = 0)
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_s <= 8'h00;
            rx_cnt_s <= 3'd0;
            rx_byte_s <= 8'h00;
            rx_tgl_s <= 1'b0;
        end else if (cs_n) begin
            rx_shift_s <= 8'h00;
            rx_cnt_s <= 3'd0;
        end else begin
            rx_shift_s <= {rx_shift_s[6:0], mosi};

            if (rx_cnt_s == 3'd7) begin
                rx_byte_s <= {rx_shift_s[6:0], mosi};
                rx_cnt_s <= 3'd0;
                rx_tgl_s <= ~rx_tgl_s;
            end else begin
                rx_cnt_s <= rx_cnt_s + 3'd1;
            end
        end
    end

    // registre pentru transmiterea datelor pe MISO
    reg [7:0] tx_shift_s;
    reg [2:0] tx_cnt_s;

    // incarcare primului bit la activarea CS
    always @(negedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_s <= 8'h00;
            tx_cnt_s <= 3'd0;
            miso <= 1'b0;
        end else begin
            tx_shift_s <= data_out;
            tx_cnt_s <= 3'd0;
            miso <= data_out[7];
        end
    end

    // transmitere MISO pe front descrescator (CPHA = 0)
    always @(negedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_s <= 8'h00;
            tx_cnt_s <= 3'd0;
            miso <= 1'b0;
        end else if (cs_n) begin
            tx_shift_s <= 8'h00;
            tx_cnt_s <= 3'd0;
            miso <= 1'b0;
        end else begin
            if (tx_cnt_s == 3'd7) begin
                tx_shift_s <= data_out;
                tx_cnt_s <= 3'd0;
                miso <= data_out[7];
            end else begin
                tx_cnt_s <= tx_cnt_s + 3'd1;
                miso <= tx_shift_s[6 - tx_cnt_s];
            end
        end
    end

    // sincronizare semnal byte primit in domeniul clk
    reg rx_tgl_ff1;
    reg rx_tgl_ff2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_tgl_ff1 <= 1'b0;
            rx_tgl_ff2 <= 1'b0;
            byte_sync <= 1'b0;
            data_in <= 8'h00;
        end else begin
            rx_tgl_ff1 <= rx_tgl_s;
            rx_tgl_ff2 <= rx_tgl_ff1;

            byte_sync <= rx_tgl_ff2 ^ rx_tgl_ff1;
            if (rx_tgl_ff2 ^ rx_tgl_ff1)
                data_in <= rx_byte_s;
        end
    end

endmodule