module spi_bridge (
    // Semnalele de ceas si reset ale sistemului (FPGA)
    input clk,
    input rst_n,
    
    // Semnalele externe SPI (Interface with Master)
    input sclk,         // Ceasul SPI venit de la Master
    input cs_n,         // Chip Select (activ pe 0) - ne activeaza pe noi
    input mosi,         // Master Out Slave In - pe aici primim biti
    output reg miso,    // Master In Slave Out - pe aici trimitem biti
    
    // Interfata interna (paralela) catre restul logicii noastre
    output reg byte_sync,      // Puls care anunta: "Hei, am primit un octet complet!"
    output reg [7:0] data_in,  // Octetul compus din bitii primiti de pe MOSI
    input [7:0] data_out       // Octetul pe care trebuie sa il spargem in biti pe MISO
);

    // --- Sincronizare Semnale ---
    // SCLK si CS_N sunt semnale asincrone fata de ceasul nostru (clk).
    // Trebuie sa le trecem prin flip-flop-uri ca sa evitam metastabilitatea
    // si sa putem detecta fronturile (rising/falling edge).
    reg [2:0] sclk_sync;
    reg [2:0] cs_sync;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            cs_sync <= 3'b111;
        end else begin
            // Shiftam valorile vechi si bagam valoarea noua in dreapta
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_sync <= {cs_sync[1:0], cs_n};
        end
    end

    // Detectam fronturile uitandu-ne la ultimele 2 valori din registru
    // 01 inseamna ca a crescut (Rising), 10 inseamna ca a scazut (Falling)
    wire sclk_rising  = (sclk_sync[2:1] == 2'b01);
    wire sclk_falling = (sclk_sync[2:1] == 2'b10);
    wire cs_active    = (cs_sync[2] == 0); // CS e activ cand e 0 logic

    // Registre interne pentru procesarea bitilor
    reg [7:0] shift_reg; // Aici colectam bitii care vin
    reg [2:0] bit_cnt;   // Numaram cati biti am procesat (0..7)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Resetare generala
            bit_cnt <= 0;
            shift_reg <= 0;
            data_in <= 0;
            byte_sync <= 0;
            miso <= 0;
        end else begin
            byte_sync <= 0; // Pulsul trebuie sa stea pe 1 doar un singur ciclu de ceas

            // Daca Chip Select nu e activ (e 1), resetam logica SPI
            if (!cs_active) begin
                bit_cnt <= 0;
                miso <= 0; // Tinem linia jos cand nu vorbim
            end else begin
                // --- RECEPTIE (MOSI) ---
                // Standardul zice ca citim datele pe frontul crescator al ceasului SPI
                if (sclk_rising) begin
                    // Shiftam bitul nou venit in dreapta (LSB)
                    shift_reg <= {shift_reg[6:0], mosi}; 
                    bit_cnt <= bit_cnt + 1;
                    
                    // Daca am numarat 7 (deci am procesat bitii 0..7), avem un octet!
                    if (bit_cnt == 7) begin
                        data_in <= {shift_reg[6:0], mosi}; // Salvam octetul final
                        byte_sync <= 1; // Dam semnal la decodor sa ia datele
                        bit_cnt <= 0;   // Resetam contorul pentru urmatorul octet
                    end
                end

                // --- TRANSMISIE (MISO) ---
                // Standardul zice ca schimbam datele pe frontul descrescator
                if (sclk_falling) begin
                    if (bit_cnt == 0) begin
                        // Suntem la inceputul unui octet nou.
                        // Luam bitul cel mai semnificativ (MSB - bit 7) din datele
                        // pregatite de decodor (data_out) si il punem pe fir.
                        miso <= data_out[7];
                    end else begin
                        // Altfel, punem urmatorii biti descrescator (6, 5, 4...)
                        // Folosim matematica: 7 - bit_cnt ne da indexul corect.
                        miso <= data_out[7 - bit_cnt]; 
                    end
                end
            end
        end
    end
endmodule