import cv2
import numpy as np
import os

def image_to_hex(input_image_path, output_hex_path, resize_dimensions=(512, 512)):
    """
    Convert an image file to hex values and save to a file.
    Resizes the image to the specified dimensions.
    
    Args:
        input_image_path: Path to the input image file
        output_hex_path: Path to save the hex values
        resize_dimensions: Tuple of (width, height) for resizing the image
    """
    # Read the image
    img = cv2.imread(input_image_path)
    if img is None:
        raise FileNotFoundError(f"Could not open or find the image: {input_image_path}")
    
    # Resize the image
    img_resized = cv2.resize(img, resize_dimensions)
    
    # Convert to grayscale if it's a color image
    if len(img_resized.shape) == 3:
        img_gray = cv2.cvtColor(img_resized, cv2.COLOR_BGR2GRAY)
    else:
        img_gray = img_resized
    
    # Convert pixel values to hex and write to file
    with open(output_hex_path, 'w') as f:
        height, width = img_gray.shape
        f.write(f"// Image dimensions: {width}x{height}\n")
        f.write(f"// Format: 8-bit grayscale\n")
        
        for y in range(height):
            for x in range(width):
                pixel_value = img_gray[y, x]
                hex_value = format(pixel_value, '02x')
                f.write(hex_value + "\n")
    
    print(f"Converted {input_image_path} to hex format and saved to {output_hex_path}")
    print(f"Image resized to {resize_dimensions[0]}x{resize_dimensions[1]}")
    print(f"Total pixels: {resize_dimensions[0] * resize_dimensions[1]}")

if __name__ == "__main__":
    input_image = "image.jpg"
    output_hex = "image_hex.txt"
    
    # Check if input image exists
    if not os.path.exists(input_image):
        print(f"Error: {input_image} not found!")
        exit(1)
    
    # Convert image to hex
    image_to_hex(input_image, output_hex)