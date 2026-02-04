// Example 2: Arithmetic operations
// Demonstrates calculations and number output

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

int main() {
    int a = 15;
    int b = 27;
    
    print_string("a = ");
    print_int(a);
    print_string(", b = ");
    print_int(b);
    print_char('\n');
    
    print_string("a + b = ");
    print_int(a + b);
    print_char('\n');
    
    print_string("a - b = ");
    print_int(a - b);
    print_char('\n');
    
    print_string("a * b = ");
    print_int(a * b);
    print_char('\n');
    
    return 0;
}
