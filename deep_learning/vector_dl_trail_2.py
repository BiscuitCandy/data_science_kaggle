import numpy as np
import json

def sigmoid(z):
    return 1 / (1 + np.exp(-z))

def relu(z):
    return np.maximum(0, z)

def tanh(z):
    return np.tanh(z)

def forward(x, w1, w2, w3, activation_fn):
    if activation_fn == 'logistic':
        activation = sigmoid
    elif activation_fn == 'relu':
        activation = relu
    elif activation_fn == 'tanh':
        activation = tanh
    else:
        raise ValueError("Invalid activation function")

    # Hidden layer 1
    h1 = activation(np.dot(x, w1))
    # Hidden layer 2
    # h1 = np.reshape(1, 30)
    h2 = activation(np.dot(h1, w2))
    # Output layer
    y_pred = activation(np.dot(h2, w3))

    # Return all values computed in forward pass
    return h1, h2, y_pred

def backward(x, y, h1, h2, w1, w2, w3, activation_fn):
    if activation_fn == 'logistic':
        activation_derivative = lambda z: sigmoid(z) * (1 - sigmoid(z))
    elif activation_fn == 'relu':
        activation_derivative = lambda z: np.where(z > 0, 1, 0)
    elif activation_fn == 'tanh':
        activation_derivative = lambda z: 1 - np.square(np.tanh(z))
    else:
        raise ValueError("Invalid activation function")

    # Output layer error
    h2 = h2.reshape(-1, w3.shape[0])
    delta3 = (y - y_pred) * activation_derivative(np.dot(h2, w3))
    # Hidden layer 2 error
    delta2 = activation_derivative(np.dot(w2, h1)) * np.dot(w3.T, delta3)
    # Hidden layer 1 error
    delta1 = np.dot(w2.T, delta2) * activation_derivative(np.dot(w1, x))

    # Compute the gradients
    grad_w3 = np.dot(delta3, h2.T)
    grad_w2 = np.dot(delta2, h1.T)
    grad_w1 = np.dot(delta1, x.T)

    # print("*"*10)
    # print(grad_w1, grad_w2, grad_w3)
    # print("*"*10)

    # Return the gradients
    return grad_w1, grad_w2, grad_w3

# Test the network with sample data
with open("input.txt") as f :
    l = f.readlines()

    x = np.array(json.loads(l[0]))
    # x = x.reshape(*x.shape, 1)
    # print(x)
    y = np.array(json.loads(l[1]))
    # y = y.reshape(*y.shape, 1)
    w1 = np.array(json.loads(l[2]))
    # print(w1)
    w2 = np.array(json.loads(l[3]))
    w3 = np.array(json.loads(l[4]))
    activation_fn = l[5].strip().lower()

# Compute the forward pass
h1, h2, y_pred = forward(x, w1, w2, w3, activation_fn)

# print(h1, h2, y_pred)

# Compute the backward pass
grad_w1, grad_w2, grad_w3 = backward(x, y, h1, h2, w1, w2, w3, activation_fn)

# Print the gradients
print("Gradient w1:\n", grad_w1)
print("Gradient w2:\n", grad_w2)
print("Gradient w3:\n", grad_w3)