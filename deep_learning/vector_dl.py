import numpy as np

def sigmoid(z):
    return 1 / (1 + np.exp(-z))

def relu(z):
    return np.maximum(0, z)

def tanh(z):
    return np.tanh(z)

def forward(x, w1, w2, w3, activation_fn):
    if activation_fn == 'sigmoid':
        activation = sigmoid
    elif activation_fn == 'relu':
        activation = relu
    elif activation_fn == 'tanh':
        activation = tanh
    else:
        raise ValueError("Invalid activation function")

    # Hidden layer 1
    h1 = activation(np.dot(w1, x))
    # Hidden layer 2
    h2 = activation(np.dot(w2, h1))
    # Output layer
    y_pred = activation(np.dot(w3, h2))

    # Return all values computed in forward pass
    return h1, h2, y_pred

def backward(x, y, h1, h2, w1, w2, w3, activation_fn):
    if activation_fn == 'sigmoid':
        activation_derivative = lambda z: sigmoid(z) * (1 - sigmoid(z))
    elif activation_fn == 'relu':
        activation_derivative = lambda z: np.where(z > 0, 1, 0)
    elif activation_fn == 'tanh':
        activation_derivative = lambda z: 1 - np.square(np.tanh(z))
    else:
        raise ValueError("Invalid activation function")

    # Output layer error
    delta3 = (y - y_pred) * activation_derivative(np.dot(w3, h2))
    # Hidden layer 2 error
    delta2 = np.dot(w3.T, delta3) * activation_derivative(np.dot(w2, h1))
    # Hidden layer 1 error
    delta1 = np.dot(w2.T, delta2) * activation_derivative(np.dot(w1, x))

    # Compute the gradients
    grad_w3 = np.dot(delta3, h2.T)
    grad_w2 = np.dot(delta2, h1.T)
    grad_w1 = np.dot(delta1, x.T)

    # Return the gradients
    return grad_w1, grad_w2, grad_w3

# Test the network with sample data
x = np.array([[2], [1]])
y_true = np.array([[0], [1]])
w1 = np.array([[0.1, 0.2], [0.3, 0.4]])
w2 = np.array([[0.1, 0.2], [0.3, 0.4]])
w3 = np.array([[0.1, 0.2], [0.3, 0.4]])
activation_fn = 'sigmoid'

# Compute the forward pass
h1, h2, y_pred = forward(x, w1, w2, w3, activation_fn)

# Compute the backward pass
grad_w1, grad_w2, grad_w3 = backward(x, y_true, h1, h2, w1, w2, w3, activation_fn)

# Print the gradients
print("Gradient w1:\n", grad_w1)
print("Gradient w2:\n", grad_w2)
print("Gradient w3:\n", grad_w3)
