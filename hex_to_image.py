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
    # Initialize an empty array for the image
    img = np.zeros((height, width), dtype=np.uint8)
    
    # Read hex values from file
    try:
        with open(input_hex_path, 'r') as f:
            lines = f.readlines()
            
        # Skip comment lines that start with '//'
        pixel_lines = [line.strip() for line in lines if not line.strip().startswith('//')]
        
        # Check if we have enough pixel values
        if len(pixel_lines) < width * height:
            print(f"Warning: Expected {width * height} pixels, but found {len(pixel_lines)}")
        
        # Fill the image array with pixel values
        pixel_index = 0
        # Fill the image array with RGB pixel values
        img = np.zeros((height, width, 3), dtype=np.uint8)

        for y in range(height):
            for x in range(width):
                if pixel_index < len(pixel_lines):
                    hex_str = pixel_lines[pixel_index]
                    try:
                        r = int(hex_str[0:2], 16)
                        g = int(hex_str[2:4], 16)
                        b = int(hex_str[4:6], 16)
                        img[y, x] = [b, g, r]  # OpenCV BGR format
                    except ValueError:
                        img[y, x] = [0, 0, 0]
                pixel_index += 1

        
        # Save the image
        cv2.imwrite(output_image_path, img)
        print(f"Converted hex data from {input_hex_path} to image and saved to {output_image_path}")
        
    except Exception as e:
        print(f"Error converting hex to image: {e}")
        return False
    
    return True

if __name__ == "__main__":
    input_hex = "output_hex.txt"
    output_image = "processed_image.jpg"
    
    # Check if input hex file exists
    if not os.path.exists(input_hex):
        print(f"Error: {input_hex} not found!")
        exit(1)
    
    # Convert hex to image
    hex_to_image(input_hex, output_image)