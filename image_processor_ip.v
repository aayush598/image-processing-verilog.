module image_processor_bram #(
    parameter IMAGE_WIDTH = 512,
    parameter IMAGE_HEIGHT = 512,
    parameter IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [1:0] operation_select,
    input wire [7:0] threshold_value,
    input wire [7:0] brightness_value,
    output reg done,
    output reg [23:0] pixel_out,
    output reg pixel_valid_out
);

    // BRAM declaration
    reg [23:0] bram [0:IMAGE_SIZE-1];

    // FSM state encoding
    reg [1:0] state;
    parameter IDLE = 2'b00, READ = 2'b01, PROCESS = 2'b10, WRITE = 2'b11;

    integer addr;

    // Temporary registers
    reg [23:0] pixel;
    wire [7:0] r = pixel[23:16];
    wire [7:0] g = pixel[15:8];
    wire [7:0] b = pixel[7:0];

    reg [9:0] r_mod, g_mod, b_mod;
    reg [15:0] gray_calc;
    reg [7:0] gray;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            addr <= 0;
            done <= 0;
            pixel_valid_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    pixel_valid_out <= 0;
                    if (start) begin
                        addr <= 0;
                        state <= READ;
                    end
                end

                READ: begin
                    if (addr < IMAGE_SIZE) begin
                        pixel <= bram[addr];
                        state <= PROCESS;
                    end else begin
                        done <= 1;
                        state <= IDLE;
                    end
                end

                PROCESS: begin
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
                            gray_calc = r * 8'd77 + g * 8'd150 + b * 8'd29;
                            gray = gray_calc[15:8];
                            pixel_out <= {gray, gray, gray};
                        end
                    endcase
                    pixel_valid_out <= 1;
                    state <= WRITE;
                end

                WRITE: begin
                    bram[addr] <= pixel_out;
                    addr <= addr + 1;
                    state <= READ;
                end
            endcase
        end
    end

endmodule
