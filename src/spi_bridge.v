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

    // sincronizam sclk si cs_n pe clk (pentru detectie de fronturi)
    reg [2:0] sclk_sync;
    reg [2:0] cs_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            cs_sync <= 3'b111;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_sync <= {cs_sync[1:0], cs_n};
        end
    end

    wire sclk_rising = (sclk_sync[2:1] == 2'b01);
    wire sclk_falling = (sclk_sync[2:1] == 2'b10);

    wire cs_active = (cs_sync[2] == 1'b0);
    wire cs_falling = (cs_sync[2:1] == 2'b10);

    // receptie MOSI
    reg [7:0] rx_shift;
    reg [2:0] rx_bit;

    // transmisie MISO
    reg [7:0] tx_byte;
    reg [2:0] tx_bit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_sync <= 1'b0;
            data_in <= 8'h00;

            rx_shift <= 8'h00;
            rx_bit <= 3'd7;

            tx_byte <= 8'h00;
            tx_bit <= 3'd7;

            miso <= 1'b0;

        end else begin
            // default: byte_sync este puls de 1 clk
            byte_sync <= 1'b0;

            // daca nu suntem selectati, tinem totul in stare initiala
            if (!cs_active) begin
                rx_bit <= 3'd7;
                tx_bit <= 3'd7;
                miso <= 1'b0;

            end else begin
                // la inceput de tranzactie (cs_n cade), punem primul bit pe MISO
                // CPHA=0: masterul citeste pe rising, noi schimbam pe falling,
                // dar primul bit e bine sa fie pregatit imediat cand incepe tranzactia
                if (cs_falling) begin
                    tx_byte <= data_out;
                    tx_bit <= 3'd7;
                    miso <= data_out[7];
                end

                // citim MOSI pe frontul crescator (CPOL=0, CPHA=0)
                if (sclk_rising) begin
                    rx_shift[rx_bit] <= mosi;

                    if (rx_bit == 3'd0) begin
                        // byte complet
                        data_in <= {rx_shift[7:1], mosi};
                        byte_sync <= 1'b1;
                        rx_bit <= 3'd7;
                    end else begin
                        rx_bit <= rx_bit - 3'd1;
                    end
                end

                // schimbam MISO pe frontul descrescator (CPOL=0, CPHA=0)
                if (sclk_falling) begin
                    // daca suntem la inceput de byte, incarcam ce trebuie trimis acum
                    // (asta ajuta mai ales la READ: dupa comanda, instr_dcd/regs pregatesc data_out)
                    if (tx_bit == 3'd7) begin
                        tx_byte <= data_out;
                        miso <= data_out[7];
                        tx_bit <= 3'd6;
                    end else begin
                        miso <= tx_byte[tx_bit];
                        if (tx_bit == 3'd0)
                            tx_bit <= 3'd7;
                        else
                            tx_bit <= tx_bit - 3'd1;
                    end
                end
            end
        end
    end

endmodule
