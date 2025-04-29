`timescale 1ns / 1ps

module image_processor(
    input wire clk,
    input wire rst,
    input wire [23:0] pixel_in,
    input wire [1:0] operation_select, // 00: invert, 01: threshold, 10: brightness, 11: grayscale
    input wire [7:0] threshold_value,
    input wire [7:0] brightness_value,
    input wire data_valid_in,
    output reg [23:0] pixel_out,
    output reg data_valid_out
);

    wire [7:0] r = pixel_in[23:16];
    wire [7:0] g = pixel_in[15:8];
    wire [7:0] b = pixel_in[7:0];

    reg [9:0] r_mod, g_mod, b_mod;
    reg [15:0] gray_calc;
    reg [7:0] gray;

    always @(posedge clk) begin
        if (rst) begin
            data_valid_out <= 0;
            pixel_out <= 24'h000000;
        end else if (data_valid_in) begin
            case (operation_select)
                2'b00: begin // Invert
                    pixel_out <= {~r, ~g, ~b};
                end
                2'b01: begin // Threshold
                    pixel_out[23:16] <= (r > threshold_value) ? 8'hFF : 8'h00;
                    pixel_out[15:8]  <= (g > threshold_value) ? 8'hFF : 8'h00;
                    pixel_out[7:0]   <= (b > threshold_value) ? 8'hFF : 8'h00;
                end
                2'b10: begin // Brightness adjustment
                    r_mod = (brightness_value < 128) ? (r + brightness_value) : (r - (256 - brightness_value));
                    g_mod = (brightness_value < 128) ? (g + brightness_value) : (g - (256 - brightness_value));
                    b_mod = (brightness_value < 128) ? (b + brightness_value) : (b - (256 - brightness_value));

                    pixel_out[23:16] <= (r_mod > 255) ? 8'hFF : (r_mod[9] ? 8'h00 : r_mod[7:0]);
                    pixel_out[15:8]  <= (g_mod > 255) ? 8'hFF : (g_mod[9] ? 8'h00 : g_mod[7:0]);
                    pixel_out[7:0]   <= (b_mod > 255) ? 8'hFF : (b_mod[9] ? 8'h00 : b_mod[7:0]);
                end
                2'b11: begin // Grayscale using weights: 0.299R + 0.587G + 0.114B
                    gray_calc = r * 77 + g * 150 + b * 29;
                    gray = gray_calc[15:8];
                    pixel_out <= {gray, gray, gray};
                end
            endcase
            data_valid_out <= 1;
        end else begin
            data_valid_out <= 0;
        end
    end
endmodule
