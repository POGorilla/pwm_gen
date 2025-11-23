/*
    DO NOT, UNDER ANY CIRCUMSTANCES, MODIFY THIS FILE! THIS HAS TO REMAIN AS SUCH IN ORDER 
    FOR THE TESTBENCH PROVIDED TO WORK PROPERLY.
*/
module top(
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input miso, // ATENTIE: Aici e input in antet, dar logic ar trebui sa fie output (MISO)
    output mosi, // ATENTIE: Aici e output in antet, dar logic ar trebui sa fie input (MOSI)
    // peripheral signals
    output pwm_out
);

// Firele standard pentru conexiuni
wire clk;
wire rst_n;

wire sclk;
wire cs_n;
wire miso;
wire mosi;

// Firele interne (interfata paralela intre module)
wire byte_sync;      // Semnal de sincronizare intre bridge si decodor
wire[7:0] data_in;   // Date de la Bridge -> Decodor
wire[7:0] data_out;  // Date de la Decodor -> Bridge
wire read;           // Semnal comanda READ
wire write;          // Semnal comanda WRITE
wire[5:0] addr;      // Adresa registrului accesat
wire[7:0] data_read; // Valoarea citita din registru
wire[7:0] data_write;// Valoarea de scris in registru

// Firele de configurare (ies din Registri si intra in Counter/PWM)
wire[15:0] counter_val;
wire[15:0] period;
wire en;
wire count_reset;
wire upnotdown;
wire[7:0] prescale;

wire pwm_en;
wire[7:0] functions;
wire[15:0] compare1;
wire[15:0] compare2;

// --- Instantiere SPI BRIDGE ---
// AICI ESTE PARTEA IMPORTANTA ("HACK"-ul pentru pini):
// Antetul impus de tema defineste 'miso' ca INPUT si 'mosi' ca OUTPUT.
// Asta este invers fata de cum functioneaza un Slave SPI (care asculta pe MOSI si vorbeste pe MISO).
// Pentru a rezolva asta fara sa schimbam antetul, facem conexiunea incrucisata:
spi_bridge i_spi_bridge (
    .clk(clk),
    .rst_n(rst_n),
    .sclk(sclk),
    .cs_n(cs_n),
    
    // Pinul fizic 'miso' (care e input in top) il legam la intrarea 'mosi' a bridge-ului nostru.
    // Practic, Masterul trimite date pe linia pe care a numit-o gresit 'miso'.
    .mosi(miso),        
    
    // Iesirea bridge-ului nostru 'miso' o legam la pinul fizic 'mosi' (care e output in top).
    // Practic, noi raspundem pe linia pe care ei au numit-o gresit 'mosi'.
    .miso(mosi),        
    
    // Conectam interfata interna (byte-ul paralel)
    .byte_sync(byte_sync),
    .data_in(data_in),
    .data_out(data_out)
);

// --- Instantiere DECODOR DE INSTRUCTIUNI ---
// Modulul care interpreteaza comenzile (primul byte) si seteaza adresele
instr_dcd i_instr_dcd (
    .clk(clk),
    .rst_n(rst_n),
    .byte_sync(byte_sync), // Cand bridge-ul zice ca are un byte, decodorul il ia
    .data_in(data_in),
    .data_out(data_out),
    .read(read),
    .write(write),
    .addr(addr),
    .data_read(data_read),
    .data_write(data_write)
);

// --- Instantiere REGISTRI ---
// Banca de memorie care tine minte configuratia (perioada, compare, etc.)
regs i_regs (
    .clk(clk),
    .rst_n(rst_n),
    // Interfata cu decodorul
    .read(read),
    .write(write),
    .addr(addr),
    .data_read(data_read),
    .data_write(data_write),
    // Iesirile de configurare catre Counter si PWM
    .counter_val(counter_val),
    .period(period),
    .en(en),
    .count_reset(count_reset),
    .upnotdown(upnotdown),
    .prescale(prescale),
    .pwm_en(pwm_en),
    .functions(functions),
    .compare1(compare1),
    .compare2(compare2)
);

// --- Instantiere NUMARATOR ---
// Baza de timp a sistemului
counter i_counter (
    .clk(clk),
    .rst_n(rst_n),
    .count_val(counter_val), // Valoarea curenta se duce inapoi la Regs (pentru citire) si la PWM
    .period(period),
    .en(en),
    .count_reset(count_reset),
    .upnotdown(upnotdown),
    .prescale(prescale)
);

// --- Instantiere GENERATOR PWM ---
// Logica care scoate 0 sau 1 in functie de comparatii
pwm_gen i_pwm_gen (
    .clk(clk),
    .rst_n(rst_n),
    .pwm_en(pwm_en),
    .period(period),
    .functions(functions),
    .compare1(compare1),
    .compare2(compare2),
    .count_val(counter_val),
    .pwm_out(pwm_out) // Semnalul final de iesire
);

endmodule