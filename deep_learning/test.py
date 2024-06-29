import numpy as np

# create a 2d array with shape (3, 4)
a = np.array([[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]])

# reshape to a 3d array with shape (3, 4, 1)
b = a.reshape((3, 4, 1))

print(a)  # output: (3, 4)
print(b)  # output: (3, 4, 1)
