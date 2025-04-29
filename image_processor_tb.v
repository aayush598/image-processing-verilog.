`timescale 1ns / 1ps

module image_processor_tb;

    // Inputs to the DUT
    reg clk;
    reg rst;
    reg [23:0] pixel_in;
    reg [1:0] operation_select;
    reg [7:0] threshold_value;
    reg [7:0] brightness_value;
    reg data_valid_in;

    // Outputs from the DUT
    wire [23:0] pixel_out;
    wire data_valid_out;

    // File variables
    integer input_file, output_file;
    reg [71:0] hex_string;
    integer read_status;
    integer total_pixels, i;

    // Pixel data
    reg [23:0] pixel_data;

    // Instantiate the module under test
    image_processor uut (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .operation_select(operation_select),
        .threshold_value(threshold_value),
        .brightness_value(brightness_value),
        .data_valid_in(data_valid_in),
        .pixel_out(pixel_out),
        .data_valid_out(data_valid_out)
    );

    // Generate clock: 10ns period
    always begin
        #5 clk = ~clk;
    end

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        data_valid_in = 0;
        pixel_in = 24'h000000;
        operation_select = 2'b01;        // 10 = brightness, 11 = grayscale
        threshold_value = 8'd128;
        brightness_value = 8'd80;
        total_pixels = 512 * 512;

        // Wait and release reset
        #20 rst = 0;

        // Open input file
        input_file = $fopen("image_hex.txt", "r");
        if (input_file == 0) begin
            $display("ERROR: Cannot open image_rgb_hex.txt");
            $finish;
        end

        // Open output file
        output_file = $fopen("output_hex.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: Cannot open output_rgb_hex.txt");
            $finish;
        end

        // Skip comment lines
        read_status = $fgets(hex_string, input_file);
        while (hex_string[71:64] == "//") begin
            read_status = $fgets(hex_string, input_file);
        end

        // Process pixels
        for (i = 0; i < total_pixels; i = i + 1) begin
            read_status = $sscanf(hex_string, "%h", pixel_data);
            pixel_in = pixel_data;
            data_valid_in = 1;

            @(posedge clk);

            if (data_valid_out) begin
                $fwrite(output_file, "%06x\n", pixel_out);
            end

            if (!$feof(input_file)) begin
                read_status = $fgets(hex_string, input_file);
            end
        end

        // Done
        $fclose(input_file);
        $fclose(output_file);
        $display("✅ Verilog simulation complete. Output saved to output_rgb_hex.txt");
        $finish;
    end
endmodule
