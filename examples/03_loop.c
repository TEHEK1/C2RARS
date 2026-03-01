// Example 3: Loop demonstration
// Shows for/while loops working with C2RARS

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
    print_string("Countdown from 10:\n");
    
    // For loop
    for (int i = 10; i >= 1; i--) {
        print_int(i);
        print_string("... ");
    }
    
    print_string("\nLiftoff!\n");
    
    // While loop - sum from 1 to 10
    print_string("\nSum from 1 to 10:\n");
    int sum = 0;
    int n = 1;
    
    while (n <= 10) {
        sum = sum + n;
        n++;
    }
    
    print_string("Result: ");
    print_int(sum);
    print_char('\n');
    
    return 0;
}
