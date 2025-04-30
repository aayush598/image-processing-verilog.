module image_processor(
    input wire clk,
    input wire rst,
    input wire [1:0] operation_select, // 00: invert, 01: threshold, 10: brightness, 11: grayscale
    input wire [7:0] threshold_value,
    input wire [7:0] brightness_value,
    
    // Pixel input interface
    input wire pixel_valid_in,
    input wire [23:0] pixel_in,
    
    // Pixel output interface
    output reg pixel_valid_out,
    output reg [23:0] pixel_out
);

    // Extract color channels
    wire [7:0] r = pixel_in[23:16];
    wire [7:0] g = pixel_in[15:8];
    wire [7:0] b = pixel_in[7:0];

    // Pipeline registers
    reg [1:0] operation_select_reg;
    reg [7:0] threshold_value_reg;
    reg [7:0] brightness_value_reg;
    reg [23:0] pixel_in_reg;
    reg valid_reg;

    // Intermediate calculation signals
    reg [9:0] r_mod, g_mod, b_mod;
    reg [15:0] gray_calc;
    reg [7:0] gray;

    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        if (rst) begin
            operation_select_reg <= 2'b00;
            threshold_value_reg <= 8'h00;
            brightness_value_reg <= 8'h00;
            pixel_in_reg <= 24'h000000;
            valid_reg <= 1'b0;
        end else begin
            operation_select_reg <= operation_select;
            threshold_value_reg <= threshold_value;
            brightness_value_reg <= brightness_value;
            pixel_in_reg <= pixel_in;
            valid_reg <= pixel_valid_in;
        end
    end

    // Pipeline stage 2: Perform calculations
    always @(posedge clk) begin
        if (rst) begin
            pixel_out <= 24'h000000;
            pixel_valid_out <= 1'b0;
        end else begin
            pixel_valid_out <= valid_reg;
            
            if (valid_reg) begin
                case (operation_select_reg)
                    2'b00: pixel_out <= {~r, ~g, ~b}; // Invert
                    
                    2'b01: pixel_out <= {(r > threshold_value_reg) ? 8'hFF : 8'h00,
                                        (g > threshold_value_reg) ? 8'hFF : 8'h00,
                                        (b > threshold_value_reg) ? 8'hFF : 8'h00}; // Threshold
                    
                    2'b10: begin // Brightness adjustment
                        // Calculate brightness modifications
                        r_mod = (brightness_value_reg < 128) ? (r + brightness_value_reg) : (r - (256 - brightness_value_reg));
                        g_mod = (brightness_value_reg < 128) ? (g + brightness_value_reg) : (g - (256 - brightness_value_reg));
                        b_mod = (brightness_value_reg < 128) ? (b + brightness_value_reg) : (b - (256 - brightness_value_reg));
                        
                        // Clamp values to 0-255 range
                        pixel_out[23:16] = (r_mod > 255) ? 8'hFF : (r_mod[9] ? 8'h00 : r_mod[7:0]);
                        pixel_out[15:8]  = (g_mod > 255) ? 8'hFF : (g_mod[9] ? 8'h00 : g_mod[7:0]);
                        pixel_out[7:0]   = (b_mod > 255) ? 8'hFF : (b_mod[9] ? 8'h00 : b_mod[7:0]);
                    end
                    
                    2'b11: begin // Grayscale conversion
                        gray_calc = r * 8'd77 + g * 8'd150 + b * 8'd29;
                        gray = gray_calc[15:8]; // Divide by 256 (shift right 8 bits)
                        pixel_out <= {gray, gray, gray};
                    end
                endcase
            end else begin
                pixel_out <= 24'h000000;
            end
        end
    end

endmodule