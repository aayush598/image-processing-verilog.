`timescale 1ns / 1ps

module image_processor_tb;

    // Parameters
    parameter CLK_PERIOD = 10;
    parameter IMAGE_WIDTH = 512;
    parameter IMAGE_HEIGHT = 512;
    parameter IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT;
    parameter TEST_OPERATIONS = 4;

    // Inputs to DUT
    reg clk;
    reg rst;
    reg [1:0] operation_select;
    reg [7:0] threshold_value;
    reg [7:0] brightness_value;
    reg pixel_valid_in;
    reg [23:0] pixel_in;

    // Outputs from DUT
    wire pixel_valid_out;
    wire [23:0] pixel_out;

    // Testbench variables
    integer input_file, output_file;
    integer i, op;
    reg [8*16-1:0] line;  // for reading a line from the file
    integer read_status;
    integer error_count;
    real start_time, end_time;
    integer pixel_count;

    // Operation config
    reg [1:0] test_operations [0:TEST_OPERATIONS-1];
    reg [7:0] test_thresholds [0:TEST_OPERATIONS-1];
    reg [7:0] test_brightness [0:TEST_OPERATIONS-1];

    // Replace string with reg-based string arrays
    reg [8*16-1:0] operation_names [0:TEST_OPERATIONS-1];
    reg [8*32-1:0] output_filenames [0:TEST_OPERATIONS-1];

    reg [23:0] pixel_in_reg;

    // Instantiate the image processor
    image_processor uut (
        .clk(clk),
        .rst(rst),
        .operation_select(operation_select),
        .threshold_value(threshold_value),
        .brightness_value(brightness_value),
        .pixel_valid_in(pixel_valid_in),
        .pixel_in(pixel_in),
        .pixel_valid_out(pixel_valid_out),
        .pixel_out(pixel_out)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        // Initialize test operations
        test_operations[0] = 2'b00; test_thresholds[0] = 8'd128; test_brightness[0] = 8'd80;
        test_operations[1] = 2'b01; test_thresholds[1] = 8'd128; test_brightness[1] = 8'd80;
        test_operations[2] = 2'b10; test_thresholds[2] = 8'd128; test_brightness[2] = 8'd80;
        test_operations[3] = 2'b11; test_thresholds[3] = 8'd128; test_brightness[3] = 8'd80;

        operation_names[0] = "invert";
        operation_names[1] = "threshold";
        operation_names[2] = "brightness";
        operation_names[3] = "grayscale";

        output_filenames[0] = "output_invert.txt";
        output_filenames[1] = "output_threshold.txt";
        output_filenames[2] = "output_brightness.txt";
        output_filenames[3] = "output_grayscale.txt";

        // Initialize
        clk = 0;
        rst = 1;
        pixel_valid_in = 0;
        pixel_in = 0;
        error_count = 0;
        pixel_count = 0;

        // Open input file
        input_file = $fopen("image_hex.txt", "r");
        if (input_file == 0) begin
            $display("❌ ERROR: Cannot open image_hex.txt");
            $finish;
        end

        // Skip comment lines (starting with "//")
        read_status = $fgets(line, input_file);
        while (line[8*2-1 -: 8] == "/" && line[8*1-1 -: 8] == "/") begin
            read_status = $fgets(line, input_file);
        end

        // Release reset
        #(CLK_PERIOD*2) rst = 0;

        for (op = 0; op < TEST_OPERATIONS; op = op + 1) begin
            operation_select = test_operations[op];
            threshold_value = test_thresholds[op];
            brightness_value = test_brightness[op];

            $display("⏳ Starting %s operation test...", operation_names[op]);
            start_time = $time;

            // Open output file
            output_file = $fopen(output_filenames[op], "w");
            if (output_file == 0) begin
                $display("❌ ERROR: Cannot open output file %s", output_filenames[op]);
                $finish;
            end

            $fwrite(output_file, "// Processed image - %s operation\n", operation_names[op]);
            $fwrite(output_file, "// Dimensions: %0dx%0d\n", IMAGE_WIDTH, IMAGE_HEIGHT);
            $fwrite(output_file, "// Format: 24-bit RGB\n");

            pixel_count = 0;
            while (!$feof(input_file) && pixel_count < IMAGE_SIZE) begin
                read_status = $fgets(line, input_file);
                if (line[8*2-1 -: 8] == "/" && line[8*1-1 -: 8] == "/") begin
    // Skip this iteration manually
end else begin
    read_status = $sscanf(line, "%h", pixel_in);
    pixel_in_reg = pixel_in;

    @(posedge clk);
    pixel_valid_in = 1;

    @(posedge clk);
    pixel_valid_in = 0;

    repeat(2) @(posedge clk);

    if (pixel_valid_out) begin
        $fwrite(output_file, "%06x\n", pixel_out);
        pixel_count = pixel_count + 1;

        if (pixel_out === 24'hxxxxxx) begin
            $display("⚠️  Unknown output at pixel %d", pixel_count);
            error_count = error_count + 1;
        end
    end
end


                read_status = $sscanf(line, "%h", pixel_in);
                pixel_in_reg = pixel_in;

                @(posedge clk);
                pixel_valid_in = 1;

                @(posedge clk);
                pixel_valid_in = 0;

                repeat(2) @(posedge clk);

                if (pixel_valid_out) begin
                    $fwrite(output_file, "%06x\n", pixel_out);
                    pixel_count = pixel_count + 1;

                    if (pixel_out === 24'hxxxxxx) begin
                        $display("⚠️  Unknown output at pixel %d", pixel_count);
                        error_count = error_count + 1;
                    end
                end
            end

            end_time = $time;
            $fclose(output_file);

            $display("✅ %s operation completed in %0t ns", operation_names[op], (end_time - start_time));
            $display("   Processed %0d pixels", pixel_count);
            $display("   Output saved to %s", output_filenames[op]);

            $fclose(input_file);
input_file = $fopen("image_hex.txt", "r");
if (input_file == 0) begin
    $display("❌ ERROR: Cannot reopen image_hex.txt");
    $finish;
end

read_status = $fgets(line, input_file);
while (line[8*2-1 -: 8] == "/" && line[8*1-1 -: 8] == "/") begin
    read_status = $fgets(line, input_file);
end

            while (line[8*2-1 -: 8] == "/" && line[8*1-1 -: 8] == "/") begin
                read_status = $fgets(line, input_file);
            end
        end

        $fclose(input_file);

        $display("\nTestbench completed");
        $display("Operations tested: %0d", TEST_OPERATIONS);
        $display("Total pixels processed: %0d", TEST_OPERATIONS * IMAGE_SIZE);
        $display("Errors detected: %0d", error_count);

        if (error_count == 0)
            $display("✅ All tests passed successfully!");
        else
            $display("❌ %0d errors detected!", error_count);

        $finish;
    end

    // Monitor input/output
    initial begin
        $timeformat(-9, 3, " ns", 10);
        #100;
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge pixel_valid_out);
            $display("[%t] Input: %06x -> Output: %06x", $time, pixel_in_reg, pixel_out);
        end
    end
endmodule
