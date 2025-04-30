`timescale 1ps / 1ps

module image_processor_tb;

    // Inputs to DUT
    reg clk;
    reg rst;
    reg [1:0] operation_select;
    reg [7:0] threshold_value;
    reg [7:0] brightness_value;

    // Instantiate the image processor
    image_processor uut (
        .clk(clk),
        .rst(rst),
        .operation_select(operation_select),
        .threshold_value(threshold_value),
        .brightness_value(brightness_value)
    );

    // Clock generation
    always #151 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        operation_select = 2'b11;        // 10 = Brightness
        threshold_value = 8'd128;
        brightness_value = 8'd80;

        #20 rst = 0;
        // Wait long enough for processing
        #100000000;

        $finish;
    end
endmodule
