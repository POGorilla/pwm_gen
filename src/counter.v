module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output[15:0] count_val,
    input[15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input[7:0] prescale
);
    // am nevoie de un registru intern ca sa pot modifica valoarea in always
    // pentru ca 'count_val' este outuput (implicit wire)
    reg [15:0] count_val_reg;
    
    // leg registrul intern la iesirea modulului
    assign count_val = count_val_reg;
    
    // registru pentru prescaler
    // il fac de 32biti sa fiu sigur ca incape valoarea maxima
    reg [31:0] prescale_counter;
    
    //calculez limita pana la care numara prescalerul (2 la puterea prescale)
    wire [31:0] prescale_limit;
    
    //pentru 2 la putere prescale, folosim shiftare logica la stanga
    assign prescale_limit = (1 << prescale); 

    always @(posedge clk or negedge rst_n) begin
        // reset asincron pe nivel jos (activ cand e 0)
        if (!rst_n) begin
            count_val_reg <= 16'h0000;
            prescale_counter <= 32'h1; //pornesc de la 1
        end else begin
            // reset sincron, cerut de registru (are prioritate fata de enable)
            if (count_reset) begin
                count_val_reg <= 16'h0000;
                prescale_counter <= 32'h1;
            end
            // daca modulul este activat
            else if (en) begin
                // verific daca a trecut timpul stabilit de prescaler
                if (prescale_counter >= prescale_limit) begin
                    // s-a umplut contorul de timp, il resetez
                    prescale_counter <= 32'h1;
                    
                    // modific valoarea principala a numaratorului
                    if (upnotdown) begin
                        // numarare in sus (incrementare)
                        // verific daca am ajuns la perioada maxima (period - 1)
                        if (count_val_reg >= period - 16'h1) begin
                            count_val_reg <= 16'h0000; //o iau la capat
                        end else begin
                            count_val_reg <= count_val + 16'h1;
                        end
                    end else begin
                        // numarare in jos (decrementare)
                        if (count_val_reg == 16'h0000) begin
                            // daca sunt la 0, sar la valoarea max
                            count_val_reg <= period - 16'h1;
                        end else begin
                            // nu a trecut destul timp, doar incrementez contorul de prescale
                            count_val_reg <= count_val_reg - 16'h1;
                        end
                    end
                end else begin
                    prescale_counter <= prescale_counter + 1;
                end
            end
        end
    end
endmodule