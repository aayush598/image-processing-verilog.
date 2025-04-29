`timescale 1ns / 1ps

module image_processor(
    input wire clk,
    input wire rst,
    input wire [1:0] operation_select, // 00: invert, 01: threshold, 10: brightness, 11: grayscale
    input wire [7:0] threshold_value,
    input wire [7:0] brightness_value
);

    // Pixel I/O
    reg [23:0] pixel_in;
    wire [7:0] r = pixel_in[23:16];
    wire [7:0] g = pixel_in[15:8];
    wire [7:0] b = pixel_in[7:0];

    reg [9:0] r_mod, g_mod, b_mod;
    reg [15:0] gray_calc;
    reg [7:0] gray;

    // File handling
    integer input_file, output_file;
    reg [71:0] hex_string;
    integer read_status;
    integer i;
    integer total_pixels = 512 * 512;

    // Output
    reg [23:0] pixel_out;

    initial begin
        input_file = $fopen("image_hex.txt", "r");
        if (input_file == 0) begin
            $display("❌ ERROR: Cannot open image_hex.txt");
            $finish;
        end

        output_file = $fopen("output_hex.txt", "w");
        if (output_file == 0) begin
            $display("❌ ERROR: Cannot open output_hex.txt");
            $finish;
        end

        // Skip comments
        read_status = $fgets(hex_string, input_file);
        while (hex_string[71:64] == "//") begin
            read_status = $fgets(hex_string, input_file);
        end

        // Start processing loop
        for (i = 0; i < total_pixels; i = i + 1) begin
            read_status = $sscanf(hex_string, "%h", pixel_in);

            @(posedge clk);
            if (rst) begin
                pixel_out <= 24'h000000;
            end else begin
                case (operation_select)
                    2'b00: pixel_out <= {~r, ~g, ~b};
                    2'b01: pixel_out <= {(r > threshold_value) ? 8'hFF : 8'h00,
                                         (g > threshold_value) ? 8'hFF : 8'h00,
                                         (b > threshold_value) ? 8'hFF : 8'h00};
                    2'b10: begin
                        r_mod = (brightness_value < 128) ? (r + brightness_value) : (r - (256 - brightness_value));
                        g_mod = (brightness_value < 128) ? (g + brightness_value) : (g - (256 - brightness_value));
                        b_mod = (brightness_value < 128) ? (b + brightness_value) : (b - (256 - brightness_value));
                        pixel_out[23:16] = (r_mod > 255) ? 8'hFF : (r_mod[9] ? 8'h00 : r_mod[7:0]);
                        pixel_out[15:8]  = (g_mod > 255) ? 8'hFF : (g_mod[9] ? 8'h00 : g_mod[7:0]);
                        pixel_out[7:0]   = (b_mod > 255) ? 8'hFF : (b_mod[9] ? 8'h00 : b_mod[7:0]);
                    end
                    2'b11: begin
                        gray_calc = r * 77 + g * 150 + b * 29;
                        gray = gray_calc[15:8];
                        pixel_out = {gray, gray, gray};
                    end
                endcase
                $fwrite(output_file, "%06x\n", pixel_out);
            end

            if (!$feof(input_file)) begin
                read_status = $fgets(hex_string, input_file);
            end
        end

        $fclose(input_file);
        $fclose(output_file);
        $display("✅ Processing complete. Output saved to output_hex.txt");
        $finish;
    end
endmodule
