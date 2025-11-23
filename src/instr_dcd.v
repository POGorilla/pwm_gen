module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input[7:0] data_in,
    output[7:0] data_out,
    // register access signals
    output read,
    output write,
    output[5:0] addr,
    input[7:0] data_read,
    output[7:0] data_write
);

    // Registre interne pentru iesiri
    reg [7:0] data_out_reg;
    reg read_reg;
    reg write_reg;
    reg [5:0] addr_reg;
    reg [7:0] data_write_reg;

    // Asignare la iesirile din antet
    assign data_out = data_out_reg;
    assign read = read_reg;
    assign write = write_reg;
    assign addr = addr_reg;
    assign data_write = data_write_reg;

    // Stari pentru masina de stari
    reg state;
    localparam ST_SETUP = 0;
    localparam ST_DATA  = 1;

    // Aici tinem minte comanda primita in prima faza
    reg stored_rw;     // 1 = Write, 0 = Read
    reg [5:0] stored_addr; // Adresa calculata

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_SETUP;
            read_reg <= 0;
            write_reg <= 0;
            addr_reg <= 6'h00;
            data_write_reg <= 8'h00;
            stored_rw <= 0;
            stored_addr <= 6'h00;
        end 
        else begin
            // Resetam semnalul de write (e puls de un ceas)
            write_reg <= 0; 

            // Logica se activeaza doar cand Bridge-ul ne zice ca a primit un octet
            if (byte_sync) begin
                if (state == ST_SETUP) begin
                    // Decodare Comanda 
                    // Format comanda: [7:RW] [6:High/Low] [5:0:BaseAddr]
                    
                    stored_rw <= data_in[7]; // Bitul 7 zice directia

                    // Calculam adresa fizica pentru regs
                    // Daca bitul 6 e 1 (High Byte), adunam 1 la adresa de baza
                    if (data_in[6]) 
                        stored_addr <= data_in[5:0] + 6'h01;
                    else
                        stored_addr <= data_in[5:0];

                    // Trecem in starea de date
                    state <= ST_DATA;

                    // Daca e comanda de READ, trebuie sa pregatim datele ACUM
                    if (data_in[7] == 0) begin // 0 inseamna READ
                        read_reg <= 1;
                        // Calculam adresa si aici ca sa o punem pe fire imediat
                        if (data_in[6]) addr_reg <= data_in[5:0] + 6'h01;
                        else            addr_reg <= data_in[5:0];
                    end

                end 
                else begin // state == ST_DATA
                    // Procesare Date
                    
                    if (stored_rw == 1) begin 
                        // Daca a fost WRITE, luam datele venite si le scriem in registru
                        write_reg <= 1;        // activam semnalul write
                        addr_reg <= stored_addr; // punem adresa salvata anterior
                        data_write_reg <= data_in; // punem valoarea primita
                    end 
                    
                    // Ne intoarcem la asteptare comanda noua
                    state <= ST_SETUP;
                    read_reg <= 0; // dezactivam citirea
                end
            end
        end
    end

    // Logica pentru data_out (MISO)
    // combinational, trebuie sa raspunda instant la 'read'
    always @(*) begin
        // Trimit datele citite doar daca sunt in mod READ
        if (read_reg) 
            data_out_reg = data_read;
        else 
            data_out_reg = 8'h00;
    end

endmodule