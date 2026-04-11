def add(a, b):
    """Returns the sum of two numbers."""
    return a + b


def subtract(a, b):
    """Returns the subtraction of two numbers."""
    return a - b


def multiply(a, b):
    """Returns the multiplication of two numbers."""
    return a * b


def divide(a, b):
    """Returns the division of two numbers."""
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b


def power(a, b):
    """Returns a raised to the power of b."""
    return a ** b


def factorial(n):
    """Calculates the factorial of a non-negative integer."""
    if n < 0:
        raise ValueError("Factorial is not defined for negative numbers.")

    result = 1
    for i in range(1, n + 1):
        result *= i
    return result
