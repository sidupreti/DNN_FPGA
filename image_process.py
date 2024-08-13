from PIL import Image
import numpy as np

# Function to convert to fixed-point with overflow/underflow checking
def to_fixed_point(value, fractional_bits=15):
    scale = 1 << fractional_bits
    max_val = (1 << (16 - 1)) - 1  # Max positive value for 16-bit signed
    min_val = -(1 << (16 - 1))     # Min negative value for 16-bit signed

    # Convert to fixed-point representation
    fixed_point_value = np.round(value * scale).astype(np.int32)

    # Check for overflow/underflow
    fixed_point_value = np.clip(fixed_point_value, min_val, max_val)

    return fixed_point_value.astype(np.int16)

# Load and preprocess the image
image_path = '/Users/sidupreti/Desktop/DNN_FPGA/image_data.png'
image = Image.open(image_path).convert('L')  # Convert to grayscale
image = image.resize((28, 28))  # Resize to 28x28
image_array = np.array(image)

# Normalize pixel values to the range [-1, 1] (assuming the network expects normalized input)
normalized_image = image_array / 255.0 * 2 - 1  # Scale pixel values to [-1, 1]

# Convert the normalized image to fixed-point
fixed_point_image = to_fixed_point(normalized_image, fractional_bits=15)

# Save the image to a .mem file in two's complement format
output_mem_file = '/Users/sidupreti/Desktop/DNN_FPGA/input_image.mem'
with open(output_mem_file, 'w') as f:
    for pixel in fixed_point_image.flatten():
        if pixel < 0:
            pixel = (1 << 16) + pixel  # Convert to two's complement
        f.write(f"{pixel:016b}\n")

print(f"Image processed and saved to {output_mem_file} in two's complement format.")
