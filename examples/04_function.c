// Example 4: Function calls
// Demonstrates function definitions and calls

static inline void print_int(int value) {
    register int a0 asm("a0") = value;
    register int a7 asm("a7") = 1;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

static inline void print_string(const char* str) {
    register const char* a0 asm("a0") = str;
    register int a7 asm("a7") = 4;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

static inline void print_char(char c) {
    register int a0 asm("a0") = c;
    register int a7 asm("a7") = 11;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

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
