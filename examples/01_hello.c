// Example 1: Simple Hello World with C2RARS
// Demonstrates basic string output using RARS syscalls

// RARS syscall wrappers
static inline void print_string(const char* str) {
    register const char* a0 asm("a0") = str;
    register int a7 asm("a7") = 4;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

int main() {
    print_string("Hello, world!\n");
    return 0;
}
