`timescale 1ns/1ns
module instr_dcd (
    input clk,
    input rst_n,
    input byte_sync,
    input [7:0] data_in,
    output [7:0] data_out,
    output read,
    output write,
    output [5:0] addr,
    input [7:0] data_read,
    output [7:0] data_write
);

    // registre interne pentru iesiri
    reg [7:0] data_out_reg;
    reg read_reg;
    reg write_reg;
    reg [5:0] addr_reg;
    reg [7:0] data_write_reg;

    // legam registrele interne la iesiri
    assign data_out = data_out_reg;
    assign read = read_reg;
    assign write = write_reg;
    assign addr = addr_reg;
    assign data_write = data_write_reg;

    // masina de stari:
    // ST_SETUP = primim comanda
    // ST_DATA  = primim datele
    reg state;
    localparam ST_SETUP = 1'b0;
    localparam ST_DATA = 1'b1;

    // salvam informatia din comanda
    reg stored_rw;    // 1 = write, 0 = read
    reg [5:0] stored_addr; // adresa registrului

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset
            state <= ST_SETUP;
            read_reg <= 1'b0;
            write_reg <= 1'b0;
            addr_reg <= 6'h00;
            data_write_reg <= 8'h00;
            stored_rw <= 1'b0;
            stored_addr <= 6'h00;
        end else begin
            // write este doar un puls de un clock
            write_reg <= 1'b0;

            // reactionam doar cand vine un byte nou de la SPI
            if (byte_sync) begin
                if (state == ST_SETUP) begin
                    // primul byte este comanda
                    stored_rw <= data_in[7];
                    stored_addr <= data_in[5:0];
                    state <= ST_DATA;

                    // daca este READ, activam citirea imediat
                    if (data_in[7] == 1'b0) begin
                        read_reg <= 1'b1;
                        addr_reg <= data_in[5:0];
                    end else begin
                        read_reg <= 1'b0;
                    end

                end else begin
                    // al doilea byte (datele)
                    if (stored_rw == 1'b1) begin
                        write_reg <= 1'b1;
                        addr_reg <= stored_addr;
                        data_write_reg <= data_in;
                    end

                    // revenim la asteptarea unei noi comenzi
                    state <= ST_SETUP;
                    read_reg <= 1'b0;
                end
            end
        end
    end

    // datele trimise inapoi pe MISO
    always @(*) begin
        if (read_reg)
            data_out_reg = data_read;
        else
            data_out_reg = 8'h00;
    end

endmodule
