import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
import numpy as np

# Define the neural network
class SimpleNN(nn.Module):
    def __init__(self):
        super(SimpleNN, self).__init__()
        self.fc1 = nn.Linear(784, 10)  # Hidden layer
        self.fc2 = nn.Linear(10, 10)   # Output layer

    def forward(self, x):
        x = torch.flatten(x, 1)  # Flatten the input
        x = torch.relu(self.fc1(x))
        x = self.fc2(x)
        return x

# Training function
def train_model(model, train_loader, criterion, optimizer, epochs=10):
    model.train()
    for epoch in range(epochs):
        total_loss = 0
        for data, target in train_loader:
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
        avg_loss = total_loss / len(train_loader)
        print(f'Epoch {epoch+1}/{epochs}, Loss: {avg_loss:.4f}')

# Test function to calculate accuracy
def test_model(model, test_loader):
    model.eval()
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            output = model(data)
            pred = output.argmax(dim=1, keepdim=True)  # Get the index of the max log-probability
            correct += pred.eq(target.view_as(pred)).sum().item()
    accuracy = 100. * correct / len(test_loader.dataset)
    print(f'\nTest set: Accuracy: {accuracy:.2f}%\n')
    return accuracy

# Prepare the data
transform = transforms.Compose([transforms.ToTensor()])
train_dataset = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
test_dataset = datasets.MNIST(root='./data', train=False, download=True, transform=transform)

train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=64, shuffle=True)
test_loader = torch.utils.data.DataLoader(test_dataset, batch_size=1000, shuffle=False)

# Initialize the network, loss function, and optimizer
model = SimpleNN()
criterion = nn.CrossEntropyLoss()
optimizer = optim.SGD(model.parameters(), lr=0.01)

# Train the model
train_model(model, train_loader, criterion, optimizer, epochs=10)

# Test the model
accuracy = test_model(model, test_loader)

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

# Export weights and biases to .mem files
def export_to_mem(weight, bias, layer_name, fractional_bits=15):
    # Convert to fixed-point representation
    weight_fp = to_fixed_point(weight, fractional_bits)
    bias_fp = to_fixed_point(bias, fractional_bits)

    # Save weights
    for i, w in enumerate(weight_fp):
        filename = f'{layer_name}_weights_{i}.mem'
        with open(filename, 'w') as f:
            for value in w:
                if value < 0:
                    value = (1 << 16) + value  # Convert to two's complement
                f.write(f"{value:016b}\n")

    # Save biases
    for i, b in enumerate(bias_fp):
        filename = f'{layer_name}_bias_{i}.mem'
        with open(filename, 'w') as f:
            if b < 0:
                b = (1 << 16) + b  # Convert to two's complement
            f.write(f"{b:016b}\n")

# Extract weights and biases from the trained model
hidden_weights = model.fc1.weight.detach().numpy()
hidden_bias = model.fc1.bias.detach().numpy()
output_weights = model.fc2.weight.detach().numpy()
output_bias = model.fc2.bias.detach().numpy()

# Export hidden layer weights and biases
export_to_mem(hidden_weights, hidden_bias, 'hidden')

# Export output layer weights and biases
export_to_mem(output_weights, output_bias, 'output')

print("Weights and biases converted to two's complement and exported successfully.")
