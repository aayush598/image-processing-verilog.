import cv2
import time
import numpy as np

# Load the image
image = cv2.imread('image.jpg')
if image is None:
    raise FileNotFoundError("❌ 'image.jpg' not found!")

# Resize to 512x512
resized_image = cv2.resize(image, (512, 512))

# Measure time to convert to grayscale using pure math
start_time = time.time()  # Start time in seconds

# Extract BGR channels
b = resized_image[:, :, 0].astype(np.float32)
g = resized_image[:, :, 1].astype(np.float32)
r = resized_image[:, :, 2].astype(np.float32)

# Apply grayscale formula: Gray = 0.299*R + 0.587*G + 0.114*B
gray_image = (0.299 * r + 0.587 * g + 0.114 * b).astype(np.uint8)

end_time = time.time()  # End time in seconds

# Time in milliseconds
elapsed_time_ms = (end_time - start_time) * 1000

print(f"✅ Grayscale conversion time (pure math): {elapsed_time_ms:.3f} ms")

# Optional: Save the output for verification
cv2.imwrite('grayscale_math.jpg', gray_image)
