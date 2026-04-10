#ifndef C2RARS_RARS_IO_H
#define C2RARS_RARS_IO_H

// RARS syscall wrappers for C2RARS
//
// These inline functions compile to direct ecall instructions
// compatible with the RARS RISC-V simulator.
//
// Syscall table:
//   1  - print_int          11 - print_char
//   2  - print_float (*)    12 - read_char
//   3  - print_double (*)   13 - open file
//   4  - print_string       14 - read file
//   5  - read_int           15 - write file
//   6  - read_float (*)     16 - close file
//   7  - read_double (*)    17 - exit2 (with code)
//   8  - read_string        30 - time
//   9  - sbrk               32 - sleep
//  10  - exit               34 - print_int_hex
//                           35 - print_int_bin
//  (*) require FPU          36 - print_int_unsigned

// ======================= Output =======================

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

static inline void print_int_hex(int value) {
    register int a0 asm("a0") = value;
    register int a7 asm("a7") = 34;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

static inline void print_int_bin(int value) {
    register int a0 asm("a0") = value;
    register int a7 asm("a7") = 35;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

static inline void print_int_unsigned(unsigned int value) {
    register unsigned int a0 asm("a0") = value;
    register int a7 asm("a7") = 36;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

// ======================= Input ========================

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

static inline void read_string(char* buffer, int max_length) {
    register char* a0 asm("a0") = buffer;
    register int a1 asm("a1") = max_length;
    register int a7 asm("a7") = 8;
    asm volatile ("ecall" : : "r"(a0), "r"(a1), "r"(a7) : "memory");
}

// ======================= Memory =======================

static inline void* sbrk(int num_bytes) {
    register int a0 asm("a0") = num_bytes;
    register int a7 asm("a7") = 9;
    asm volatile ("ecall" : "+r"(a0) : "r"(a7));
    return (void*)a0;
}

// ====================== File I/O ======================

static inline int file_open(const char* filename, int flags) {
    register const char* a0 asm("a0") = filename;
    register int a1 asm("a1") = flags;
    register int a7 asm("a7") = 13;
    asm volatile ("ecall" : "+r"(a0) : "r"(a1), "r"(a7));
    return (int)a0;
}

static inline int file_read(int fd, char* buffer, int length) {
    register int a0 asm("a0") = fd;
    register char* a1 asm("a1") = buffer;
    register int a2 asm("a2") = length;
    register int a7 asm("a7") = 14;
    asm volatile ("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7) : "memory");
    return a0;
}

static inline int file_write(int fd, const char* buffer, int length) {
    register int a0 asm("a0") = fd;
    register const char* a1 asm("a1") = buffer;
    register int a2 asm("a2") = length;
    register int a7 asm("a7") = 15;
    asm volatile ("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7));
    return a0;
}

static inline void file_close(int fd) {
    register int a0 asm("a0") = fd;
    register int a7 asm("a7") = 16;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

// =================== System / Misc ====================

static inline void rars_exit(int code) {
    register int a0 asm("a0") = code;
    register int a7 asm("a7") = 17;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

static inline unsigned int get_time(void) {
    register unsigned int a0 asm("a0");
    register int a7 asm("a7") = 30;
    asm volatile ("ecall" : "=r"(a0) : "r"(a7));
    return a0;
}

static inline void rars_sleep(int milliseconds) {
    register int a0 asm("a0") = milliseconds;
    register int a7 asm("a7") = 32;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

#endif // C2RARS_RARS_IO_H
