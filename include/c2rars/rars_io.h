#ifndef C2RARS_RARS_IO_H
#define C2RARS_RARS_IO_H

// RARS syscall wrappers for C2RARS
//
// These inline functions compile to direct ecall instructions
// compatible with the RARS RISC-V simulator.

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

static inline int read_int(void) {
    register int a0 asm("a0");
    register int a7 asm("a7") = 5;
    asm volatile ("ecall" : "=r"(a0) : "r"(a7));
    return a0;
}

static inline char read_char(void) {
    register int a0 asm("a0");
    register int a7 asm("a7") = 12;
    asm volatile ("ecall" : "=r"(a0) : "r"(a7));
    return (char)a0;
}

#endif // C2RARS_RARS_IO_H
