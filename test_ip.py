import cv2
import time

# Load the image
image = cv2.imread('image.jpg')
if image is None:
    raise FileNotFoundError("❌ 'image.jpg' not found!")

# Resize to 512x512
resized_image = cv2.resize(image, (512, 512))

# Measure time to convert to grayscale
start_time = time.time()  # Start time in seconds

gray_image = cv2.cvtColor(resized_image, cv2.COLOR_BGR2GRAY)

end_time = time.time()  # End time in seconds

# Time in milliseconds
elapsed_time_ms = (end_time - start_time) * 1000

print(f"✅ Grayscale conversion time: {elapsed_time_ms:.3f} ms")
