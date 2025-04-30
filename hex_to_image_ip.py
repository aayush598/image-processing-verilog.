import cv2
import numpy as np
import os

def hex_to_image(input_hex_path, output_image_path, width=512, height=512):
    """
    Convert hex values from a file back to an image.
    
    Args:
        input_hex_path: Path to the input hex file
        output_image_path: Path to save the output image
        width: Image width
        height: Image height
    """
    try:
        with open(input_hex_path, 'r') as f:
            lines = f.readlines()
            
        # Skip comment lines that start with '//'
        pixel_lines = [line.strip() for line in lines if not line.strip().startswith('//')]
        
        # Initialize image array
        img = np.zeros((height, width, 3), dtype=np.uint8)
        
        # Fill the image array with RGB pixel values
        pixel_index = 0
        for y in range(height):
            for x in range(width):
                if pixel_index < len(pixel_lines):
                    hex_str = pixel_lines[pixel_index]
                    try:
                        # Handle both 6-character and 3-character hex formats
                        if len(hex_str) == 6:
                            r = int(hex_str[0:2], 16)
                            g = int(hex_str[2:4], 16)
                            b = int(hex_str[4:6], 16)
                        elif len(hex_str) == 3:  # For grayscale outputs that might be written as 'ffffff'
                            val = int(hex_str[0], 16) * 17  # Scale to 0-255
                            r = g = b = val
                        else:
                            r = g = b = 0
                        img[y, x] = [b, g, r]  # OpenCV BGR format
                    except ValueError:
                        img[y, x] = [0, 0, 0]
                pixel_index += 1

        # Save the image
        cv2.imwrite(output_image_path, img)
        print(f"Converted hex data from {input_hex_path} to image and saved to {output_image_path}")
        return True
        
    except Exception as e:
        print(f"Error converting hex to image: {e}")
        return False

if __name__ == "__main__":
    # Process all output files
    operations = ["invert", "threshold", "brightness", "grayscale"]
    
    for op in operations:
        input_hex = f"output_{op}.txt"
        output_image = f"processed_{op}.jpg"
        
        if os.path.exists(input_hex):
            print(f"\nProcessing {input_hex}...")
            success = hex_to_image(input_hex, output_image)
            if success:
                print(f"Successfully created {output_image}")
        else:
            print(f"Skipping {input_hex} - file not found")