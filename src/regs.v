`timescale 1ns/1ns
module regs (
    input wire clk,
    input wire rst_n,
    input wire read,
    input wire write,
    input wire [5:0] addr,
    output wire [7:0] data_read,
    input wire [7:0] data_write,
    input wire [15:0] counter_val,
    output wire [15:0] period,
    output wire en,
    output wire count_reset,
    output wire upnotdown,
    output wire [7:0] prescale,
    output wire pwm_en,
    output wire [7:0] functions,
    output wire [15:0] compare1,
    output wire [15:0] compare2
);

    // registre interne care tin valorile
    reg [15:0] period_reg;
    reg en_reg;
    reg count_reset_reg;
    reg upnotdown_reg;
    reg [7:0] prescale_reg;
    reg pwm_en_reg;
    reg [7:0] functions_reg;
    reg [15:0] compare1_reg;
    reg [15:0] compare2_reg;

    // registru intern pentru citire
    reg [7:0] data_read_reg;

    // legam registrele interne la iesiri
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

    // scriere registre
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // valori default la reset
            period_reg <= 16'h0000;
            en_reg <= 1'b0;
            count_reset_reg <= 1'b0;
            upnotdown_reg <= 1'b1;
            prescale_reg <= 8'h00;
            pwm_en_reg <= 1'b0;
            functions_reg <= 8'h00;
            compare1_reg <= 16'h0000;
            compare2_reg <= 16'h0000;
        end else begin
            // count_reset este un puls de un singur clock
            count_reset_reg <= 1'b0;

            // scriere in functie de adresa
            if (write) begin
                case (addr)
                    6'h00: period_reg[7:0] <= data_write;
                    6'h01: period_reg[15:8] <= data_write;

                    6'h02: en_reg <= data_write[0];

                    6'h03: compare1_reg[7:0] <= data_write;
                    6'h04: compare1_reg[15:8] <= data_write;

                    6'h05: compare2_reg[7:0] <= data_write;
                    6'h06: compare2_reg[15:8] <= data_write;

                    6'h07: count_reset_reg <= data_write[0];

                    6'h0A: prescale_reg <= data_write;

                    6'h0B: upnotdown_reg <= data_write[0];

                    6'h0C: pwm_en_reg <= data_write[0];

                    6'h0D: functions_reg <= data_write;

                    default: ;
                endcase
            end
        end
    end

    // citire registre
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

                6'h07: data_read_reg = 8'h00;

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
