import os
import subprocess
import sys

def run_command(command, description):
    """Run a command and print its output"""
    print(f"\n=== {description} ===")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(f"Error: {result.stderr}")
    if result.returncode != 0:
        print(f"Command failed with return code {result.returncode}")
        return False
    return True

def main():
    # Input image file
    input_image = "image3.jpg"
    
    # Check if input image exists
    if not os.path.exists(input_image):
        print(f"Error: {input_image} not found!")
        return False
    
    # Step 1: Convert image to hex
    if not run_command("python image_to_hex.py", "Converting image to hex"):
        return False
    
    # Step 2: Run image processing using iverilog
    if not run_command("iverilog -o image_processor_sim image_processor.v image_processor_tb.v", "Compiling Verilog code"):
        return False
    
    if not run_command("vvp image_processor_sim", "Running image processing simulation"):
        return False
    
    # Step 3: Convert processed hex values back to image
    if not run_command("python hex_to_image.py", "Converting hex back to image"):
        return False
    
    print("\n=== All operations completed successfully! ===")
    print(f"Processed image saved as processed_image.jpg")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)