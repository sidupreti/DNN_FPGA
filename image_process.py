from PIL import Image
import numpy as np

# Load and preprocess the image
image_path = '/Users/sidupreti/Desktop/DNN_FPGA/image_data.png'
image = Image.open(image_path).convert('L')  # Convert to grayscale
image = image.resize((28, 28))  # Resize to 28x28
image_array = np.array(image)

# Normalize and convert to fixed-point
image_array = (image_array / 255.0) * (2**15)  # Normalize and scale to fixed-point range
image_array = np.round(image_array).astype(np.int16)  # Convert to fixed-point

# Save to a memory file
with open('/Users/sidupreti/Desktop/DNN_FPGA/input_image.mem', 'w') as f:
    for value in image_array.flatten():
        f.write(f"{value:04x}\n")

print("Image conversion to input_image.mem complete.")
