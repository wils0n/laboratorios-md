def generate_fibonacci(n):
    """Generates a list of the first n Fibonacci numbers."""
    if n < 0:
        raise ValueError("Input must be a non-negative integer.")

    fib_sequence = []
    a, b = 0, 1
    for _ in range(n):
        fib_sequence.append(a)
        a, b = b, a + b
    return fib_sequence


def factorial(n):
    """Calculates the factorial of a number."""
    if n < 0:
        raise ValueError("Factorial is not defined for negative numbers.")

    result = 1
    for i in range(1, n + 1):
        result *= i
    return result
