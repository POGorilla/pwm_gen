module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period,
    input[7:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output pwm_out
);

    // variabila interna pentru a calcula logica
    reg pwm_logic;
    
    // asignez rezultatul calculat la iesire
    assign pwm_out = pwm_logic;

    // combinationalul
    always @(*) begin
        // daca pwm nu este activat, iesirea trebuie sa fie 0
        if (!pwm_en) begin
            pwm_logic = 0;
        end else begin
            // bitul 1 din functions decide daca e mod nealiniat sau aliniat
            // functions[1] == 1 -> Nealiniat
            // functions[1] == 0 -> Aliniat
            if (functions[1]) begin 
                // nealiniat; semnalul e 1 doar intre compare1 si compare2
                if (count_val >= compare1 && count_val < compare2) begin
                    pwm_logic = 1;
                end else begin
                    pwm_logic = 0;
                end
            end else begin
                // aliniat; bitul 0 din functions decide daca e st sau dr
                if (functions[0] == 0) begin
                    // aliniat la st: incepe cu 1, cade pe 0 la compare1
                    if (count_val < compare1) begin
                        pwm_logic = 1;
                    end else begin
                        pwm_logic = 0;
                    end
                end else begin
                    // aliniat la dr: incepe cu 0, urca la 1 la compare1
                    if (count_val < compare1) begin
                        pwm_logic = 0;
                    end else begin
                        pwm_logic = 1;
                    end
                end
            end
        end
    end
endmodule