`timescale 1ns / 1ps

module image_processor(
    input wire clk,
    input wire rst,
    input wire [7:0] pixel_in,
    input wire [1:0] operation_select, // 00: invert, 01: threshold, 10: edge detect, 11: blur
    input wire [7:0] threshold_value,  // For threshold operation
    input wire data_valid_in,
    output reg [7:0] pixel_out,
    output reg data_valid_out
);

    // Parameters for edge detection and blur
    parameter IMG_WIDTH = 512;
    parameter IMG_HEIGHT = 512;
    
    // Line buffers for edge detection and blur
    reg [7:0] line_buffer_1 [0:IMG_WIDTH-1];
    reg [7:0] line_buffer_2 [0:IMG_WIDTH-1];
    
    // Registers for 3x3 kernel operations
    reg [7:0] window_00, window_01, window_02;
    reg [7:0] window_10, window_11, window_12;
    reg [7:0] window_20, window_21, window_22;
    
    // Position tracking
    reg [8:0] x_pos; // Use appropriate bit width for 512
    reg [8:0] y_pos; // Use appropriate bit width for 512
    
    // Control signals
    reg [2:0] valid_pipeline;
    wire kernel_valid;
    
    // For edge detection and blur operations
    reg [9:0] gx;
    reg [9:0] gy;
    reg [9:0] grad_mag;
    reg [11:0] sum;
    
    // Initialize counters
    initial begin
        x_pos = 0;
        y_pos = 0;
    end
    
    // Update position counters
    always @(posedge clk) begin
        if (rst) begin
            x_pos <= 0;
            y_pos <= 0;
        end else if (data_valid_in) begin
            if (x_pos == IMG_WIDTH - 1) begin
                x_pos <= 0;
                if (y_pos == IMG_HEIGHT - 1) begin
                    y_pos <= 0;
                end else begin
                    y_pos <= y_pos + 1;
                end
            end else begin
                x_pos <= x_pos + 1;
            end
        end
    end
    
    // Shift values through line buffers
    always @(posedge clk) begin
        if (data_valid_in) begin
            line_buffer_1[x_pos] <= pixel_in;
            line_buffer_2[x_pos] <= line_buffer_1[x_pos];
            
            // Update 3x3 window
            if (x_pos == 0 || y_pos < 2)
                window_00 <= 8'h00;
            else
                window_00 <= line_buffer_2[x_pos-1];
                
            if (y_pos < 2)
                window_01 <= 8'h00;
            else
                window_01 <= line_buffer_2[x_pos];
                
            if (x_pos == IMG_WIDTH-1 || y_pos < 2)
                window_02 <= 8'h00;
            else
                window_02 <= line_buffer_2[x_pos+1];
            
            if (x_pos == 0 || y_pos < 1)
                window_10 <= 8'h00;
            else
                window_10 <= line_buffer_1[x_pos-1];
                
            if (y_pos < 1)
                window_11 <= 8'h00;
            else
                window_11 <= line_buffer_1[x_pos];
                
            if (x_pos == IMG_WIDTH-1 || y_pos < 1)
                window_12 <= 8'h00;
            else
                window_12 <= line_buffer_1[x_pos+1];
            
            if (x_pos == 0)
                window_20 <= 8'h00;
            else if (x_pos == 1)
                window_20 <= pixel_in;
            else
                window_20 <= window_21;
                
            window_21 <= pixel_in;
            
            if (x_pos == IMG_WIDTH-1)
                window_22 <= 8'h00;
            else
                window_22 <= 8'h00; // Will be updated on next cycle
        end
    end
    
    // Validity pipeline for kernel operations
    always @(posedge clk) begin
        if (rst) begin
            valid_pipeline <= 3'b000;
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], data_valid_in};
        end
    end
    
    assign kernel_valid = valid_pipeline[2] && (y_pos >= 2) && (x_pos >= 1) && (x_pos < IMG_WIDTH-1);
    
    // Calculate edge detection values
    always @(posedge clk) begin
        if (kernel_valid && operation_select == 2'b10) begin
            // Horizontal gradient (Gx)
            gx <= window_00 + (window_01 << 1) + window_02 - window_20 - (window_21 << 1) - window_22;
            
            // Vertical gradient (Gy)
            gy <= window_00 + (window_10 << 1) + window_20 - window_02 - (window_12 << 1) - window_22;
        end
    end
    
    // Calculate gradient magnitude
    always @(posedge clk) begin
        if (kernel_valid && operation_select == 2'b10) begin
            if (gx[9] == 1) // Negative value
                grad_mag[9:0] <= (~gx + 1);
            else
                grad_mag[9:0] <= gx;
                
            if (gy[9] == 1) // Negative value
                grad_mag[9:0] <= grad_mag[9:0] + (~gy + 1);
            else
                grad_mag[9:0] <= grad_mag[9:0] + gy;
        end
    end
    
    // Calculate blur values
    always @(posedge clk) begin
        if (kernel_valid && operation_select == 2'b11) begin
            // Simple box blur (average of 3x3 window)
            sum <= window_00 + window_01 + window_02 +
                   window_10 + window_11 + window_12 +
                   window_20 + window_21 + window_22;
        end
    end
    
    // Image processing operations
    always @(posedge clk) begin
        if (rst) begin
            pixel_out <= 8'h00;
            data_valid_out <= 1'b0;
        end else begin
            case (operation_select)
                2'b00: begin // Invert
                    pixel_out <= ~pixel_in;
                    data_valid_out <= data_valid_in;
                end
                2'b01: begin // Threshold
                    pixel_out <= (pixel_in > threshold_value) ? 8'hFF : 8'h00;
                    data_valid_out <= data_valid_in;
                end
                2'b10: begin // Edge detection (Sobel)
                    if (kernel_valid) begin
                        // Clamp to 8-bit
                        if (grad_mag > 255)
                            pixel_out <= 8'hFF;
                        else
                            pixel_out <= grad_mag[7:0];
                        data_valid_out <= 1'b1;
                    end else begin
                        pixel_out <= 8'h00;
                        data_valid_out <= kernel_valid;
                    end
                end
                2'b11: begin // Blur (3x3 average)
                    if (kernel_valid) begin
                        // Divide by 9 (approximate with shift for FPGA efficiency)
                        pixel_out <= sum / 9;  // For simulation; implement with shifts in real hardware
                        data_valid_out <= 1'b1;
                    end else begin
                        pixel_out <= 8'h00;
                        data_valid_out <= kernel_valid;
                    end
                end
            endcase
        end
    end
endmodule

// Top module to handle file I/O for simulation
module image_processor_tb;
    reg clk;
    reg rst;
    reg [7:0] pixel_in;
    reg [1:0] operation_select;
    reg [7:0] threshold_value;
    reg data_valid_in;
    wire [7:0] pixel_out;
    wire data_valid_out;
    
    // File handles
    integer input_file, output_file;
    integer scan_file;
    reg [8*100:1] hex_value;
    integer i, total_pixels;
    integer read_status;
    
    // Instantiate the Unit Under Test (UUT)
    image_processor uut (
        .clk(clk), 
        .rst(rst), 
        .pixel_in(pixel_in), 
        .operation_select(operation_select), 
        .threshold_value(threshold_value),
        .data_valid_in(data_valid_in), 
        .pixel_out(pixel_out), 
        .data_valid_out(data_valid_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize inputs
        rst = 1;
        data_valid_in = 0;
        pixel_in = 0;
        operation_select = 2'b00; // Choose operation
        threshold_value = 8'd128; // Set threshold value
        
        // Open files
        input_file = $fopen("image_hex.txt", "r");
        if (input_file == 0) begin
            $display("Error: Could not open input file");
            $finish;
        end
        
        output_file = $fopen("output_hex.txt", "w");
        if (output_file == 0) begin
            $display("Error: Could not open output file");
            $finish;
        end
        
        // Skip comment lines
        scan_file = $fscanf(input_file, "%s\n", hex_value);
        while (hex_value[8*2+1:8*1+1] == "/" && hex_value[8*1+1:1] == "/") begin
            $display("Skipping comment: %s", hex_value);
            scan_file = $fscanf(input_file, "%s\n", hex_value);
        end
        
        // Release reset
        #20;
        rst = 0;
        
        // Process all pixels
        total_pixels = 512 * 512; // For 512x512 image
        
        for (i = 0; i < total_pixels; i = i + 1) begin
            @(posedge clk);
            
            // Read pixel value from file (first read already done above for the first pixel)
            if (i > 0) begin
                scan_file = $fscanf(input_file, "%s\n", hex_value);
            end
            
            // Convert hex to binary
            read_status = $sscanf(hex_value, "%h", pixel_in);
            data_valid_in = 1;
            
            // Wait for output
            @(posedge clk);
            if (data_valid_out) begin
                $fwrite(output_file, "%02x\n", pixel_out);
            end
        end
        
        // Close files
        $fclose(input_file);
        $fclose(output_file);
        
        $display("Processing complete!");
        $finish;
    end
endmodule