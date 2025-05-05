`timescale 1ns / 1ps

module tb_image_processor_bram;

    parameter IMAGE_WIDTH = 4;
    parameter IMAGE_HEIGHT = 4;
    parameter IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT;

    reg clk;
    reg rst;
    reg start;
    reg [1:0] operation_select;
    reg [7:0] threshold_value;
    reg [7:0] brightness_value;
    wire done;
    wire [23:0] pixel_out;
    wire pixel_valid_out;

    integer i;

    // Instantiate the image processor module
    image_processor_bram #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .operation_select(operation_select),
        .threshold_value(threshold_value),
        .brightness_value(brightness_value),
        .done(done),
        .pixel_out(pixel_out),
        .pixel_valid_out(pixel_valid_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test logic
    initial begin
        rst = 1;
        start = 0;
        operation_select = 2'b00;  // Negative
        threshold_value = 8'd100;
        brightness_value = 8'd30;

        #20;
        rst = 0;

        // Preload some image pixels manually
        for (i = 0; i < IMAGE_SIZE; i = i + 1) begin
            uut.bram[i] = {8'd100 + i, 8'd50 + i, 8'd25 + i};  // Simulate the image data
        end

        #20;
        start = 1;
        #10;
        start = 0;

        // Wait for processing to complete
        wait (done);

        $display("Image processing completed.\nProcessed Pixels:");
        for (i = 0; i < IMAGE_SIZE; i = i + 1) begin
            $display("Pixel[%0d] = %h", i, uut.bram[i]);
        end

        $finish;
    end

endmodule
