module regs (
    // peripheral clock signals
    input clk,
    input rst_n,
    // decoder facing signals
    input read,
    input write,
    input[5:0] addr,
    output[7:0] data_read,
    input[7:0] data_write,
    // counter programming signals
    input[15:0] counter_val,
    output[15:0] period,
    output en,
    output count_reset,
    output upnotdown,
    output[7:0] prescale,
    // PWM signal programming values
    output pwm_en,
    output[7:0] functions,
    output[15:0] compare1,
    output[15:0] compare2
);

    // declarare registre interne pentru stocare
    reg [15:0] period_reg;
    reg en_reg;
    reg count_reset_reg;
    reg upnotdown_reg;
    reg [7:0] prescale_reg;
    reg pwm_en_reg;
    reg [7:0] functions_reg;
    reg [15:0] compare1_reg;
    reg [15:0] compare2_reg;
    reg [7:0] data_read_reg;

    // legarea registrelor interne la iesirile modulului
    assign period = period_reg;
    assign en = en_reg;
    assign count_reset = count_reset_reg;
    assign upnotdown = upnotdown_reg;
    assign prescale = prescale_reg;
    assign pwm_en = pwm_en_reg;
    assign functions = functions_reg;
    assign compare1 = compare1_reg;
    assign compare2 = compare2_reg;
    assign data_read = data_read_reg;

    always @(posedge clk or negedge rst_n) begin
        //Reset Asincron (Hardware)
        if(!rst_n) begin
            // Valori default cand porneste sistemul
            period_reg <= 16'h0000;
            en_reg <= 0;
            count_reset_reg <= 0;
            upnotdown_reg <= 1; // default numaram in sus
            prescale_reg <= 8'h00;
            pwm_en_reg <= 0;
            functions_reg <= 8'h00;
            compare1_reg <= 16'h0000;
            compare2_reg <= 16'h0000;
        end 
        else begin
            // Logica de Auto-Clear pentru Reset
            // Daca s-a dat comanda de reset la counter, o tinem doar un ciclu
            if (count_reset_reg) begin
                count_reset_reg <= 0;
            end

            //Logica de SCRIERE
            if (write) begin
                case (addr)
                    // PERIOD (0x00)
                    6'h00: period_reg[7:0] <= data_write; //Low byte
                    6'h01: period_reg[15:8] <= data_write;  //High byte (offset +1)
                    
                    // COUNTER_EN (0x02)
                    6'h02: en_reg <= data_write[0]; //E doar 1 bit

                    // COMPARE1 (0x03)
                    6'h03: compare1_reg[7:0] <= data_write;
                    6'h04: compare1_reg[15:8] <= data_write;

                    // COMPARE2 (0x05)
                    6'h05: compare2_reg[7:0] <= data_write;
                    6'h06: compare2_reg[15:8] <= data_write;

                    // COUNTER_RESET (0x07)
                    6'h07: count_reset_reg <= 1; // Activam pulsul de reset

                    // Nu putem scrie la 0x08 (Counter Val e Read Only)

                    // PRESCALE (0x0A)
                    6'h0A: prescale_reg <= data_write;

                    // UPNOTDOWN (0x0B)
                    6'h0B: upnotdown_reg <= data_write[0];

                    // PWM_EN (0x0C)
                    6'h0C: pwm_en_reg <= data_write[0];

                    // FUNCTIONS (0x0D)
                    6'h0D: functions_reg <= data_write;
                    
                    default: ; // nu facem nimic daca adresa e gresita
                endcase
            end
        end
    end

    // Logica de CITIRE
    always @(*) begin
        if (read) begin
            case (addr)
                6'h00: data_read_reg = period_reg[7:0];
                6'h01: data_read_reg = period_reg[15:8];
                6'h02: data_read_reg = {7'b0, en_reg};
                6'h03: data_read_reg = compare1_reg[7:0];
                6'h04: data_read_reg = compare1_reg[15:8];
                6'h05: data_read_reg = compare2_reg[7:0];
                6'h06: data_read_reg = compare2_reg[15:8];
                
                // COUNTER_RESET e Write-Only, citim 0
                6'h07: data_read_reg = 8'h00; 

                // COUNTER_VAL (0x08) - Aici citim valoarea live din counter
                6'h08: data_read_reg = counter_val[7:0];
                6'h09: data_read_reg = counter_val[15:8];

                6'h0A: data_read_reg = prescale_reg;
                6'h0B: data_read_reg = {7'b0, upnotdown_reg};
                6'h0C: data_read_reg = {7'b0, pwm_en_reg};
                6'h0D: data_read_reg = functions_reg;
                
                default: data_read_reg = 8'h00;
            endcase
        end else begin
            data_read_reg = 8'h00;
        end
    end

endmodule