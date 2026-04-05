// Example 4: Function calls
// Demonstrates function definitions and calls

#include <c2rars/rars_io.h>

// Factorial function
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

// Fibonacci function
int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// Power function
int power(int base, int exp) {
    int result = 1;
    for (int i = 0; i < exp; i++) {
        result = result * base;
    }
    return result;
}

int main() {
    print_string("Function Examples\n");
    print_string("=================\n\n");
    
    // Factorial
    print_string("Factorial(5) = ");
    print_int(factorial(5));
    print_char('\n');
    
    // Fibonacci
    print_string("Fibonacci(7) = ");
    print_int(fibonacci(7));
    print_char('\n');
    
    // Power
    print_string("Power(2, 8) = ");
    print_int(power(2, 8));
    print_char('\n');
    
    return 0;
}
