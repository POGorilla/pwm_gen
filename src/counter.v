`timescale 1ns/1ns
module counter (
    input wire clk,
    input wire rst_n,
    output wire [15:0] count_val,
    input wire [15:0] period,
    input wire en,
    input wire count_reset,
    input wire upnotdown,
    input wire [7:0] prescale
);

    // registru intern pentru valoarea numaratorului
    reg [15:0] count_val_reg;

    // legam registrul intern la iesire
    assign count_val = count_val_reg;

    // contor folosit pentru prescaler
    reg [31:0] prescale_counter;

    // limita pana la care numara prescalerul
    wire [31:0] prescale_limit;

    // calculam 2 la puterea prescale
    assign prescale_limit = (32'd1 << prescale);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset hardware
            count_val_reg <= 16'd0;
            prescale_counter <= 32'd0;

        end else if (count_reset) begin
            // reset cerut din registri
            count_val_reg <= 16'd0;
            prescale_counter <= 32'd0;

        end else if (en) begin
            // counterul merge doar daca este activat
            if (prescale_counter >= (prescale_limit - 1)) begin
                // resetam prescalerul
                prescale_counter <= 32'd0;

                // numarare in sus
                if (upnotdown) begin
                    if (count_val_reg >= period)
                        count_val_reg <= 16'd0;
                    else
                        count_val_reg <= count_val_reg + 16'd1;

                // numarare in jos
                end else begin
                    if (count_val_reg == 16'd0)
                        count_val_reg <= period;
                    else
                        count_val_reg <= count_val_reg - 16'd1;
                end

            end else begin
                // inca nu s-a atins limita, crestem prescalerul
                prescale_counter <= prescale_counter + 32'd1;
            end
        end
    end

endmodule
