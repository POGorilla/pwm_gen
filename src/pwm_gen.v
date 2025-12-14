`timescale 1ns/1ns
module pwm_gen (
    input wire clk,
    input wire rst_n,
    input wire pwm_en,
    input wire [15:0] period,
    input wire [7:0] functions,
    input wire [15:0] compare1,
    input wire [15:0] compare2,
    input wire [15:0] count_val,
    output wire pwm_out
);

    // coduri pentru modurile PWM
    localparam [1:0] FUNCTION_ALIGN_LEFT = 2'b00;
    localparam [1:0] FUNCTION_ALIGN_RIGHT = 2'b01;
    localparam [1:0] FUNCTION_RANGE_BETWEEN_COMPARES = 2'b10;

    // semnal intern calculat
    reg pwm_logic;

    // legam semnalul intern la iesire
    assign pwm_out = pwm_logic;

    // logica PWM este combinationala
    always @(*) begin
        // valoare default
        pwm_logic = 1'b0;

        // daca PWM nu este activ, iesirea e 0
        if (!pwm_en) begin
            pwm_logic = 1'b0;

        // daca cele doua compare sunt egale, nu generam PWM
        end else if (compare1 == compare2) begin
            pwm_logic = 1'b0;

        end else begin
            // alegem modul de functionare dupa functions[1:0]
            case (functions[1:0])

                // PWM aliniat la stanga
                FUNCTION_ALIGN_LEFT: begin
                    if (compare1 != 16'd0 && count_val <= compare1)
                        pwm_logic = 1'b1;
                    else
                        pwm_logic = 1'b0;
                end

                // PWM aliniat la dreapta
                FUNCTION_ALIGN_RIGHT: begin
                    if (count_val >= compare1)
                        pwm_logic = 1'b1;
                    else
                        pwm_logic = 1'b0;
                end

                // PWM activ doar intre compare1 si compare2
                FUNCTION_RANGE_BETWEEN_COMPARES: begin
                    if (compare1 >= compare2)
                        pwm_logic = 1'b0;
                    else if ((count_val >= compare1) && (count_val < compare2))
                        pwm_logic = 1'b1;
                    else
                        pwm_logic = 1'b0;
                end

                default: pwm_logic = 1'b0;
            endcase
        end
    end

endmodule
