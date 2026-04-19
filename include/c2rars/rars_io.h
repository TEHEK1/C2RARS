#ifndef C2RARS_RARS_IO_H
#define C2RARS_RARS_IO_H

// RARS syscall wrappers for C2RARS
//
// These inline functions compile to direct ecall instructions
// compatible with the RARS RISC-V simulator.
//
// Full RARS syscall coverage (headless-relevant subset):
//   1  - print_int          11 - print_char       30 - get_time
//   2  - print_float        12 - read_char        32 - rars_sleep
//   3  - print_double       13 - file_open        34 - print_int_hex
//   4  - print_string       14 - file_read        35 - print_int_bin
//   5  - read_int           15 - file_write       36 - print_int_unsigned
//   6  - read_float         16 - file_close       40 - rng_set_seed
//   7  - read_double        17 - rars_exit        41 - rand_int
//   8  - read_string                              42 - rand_int_range
//   9  - sbrk                                     43 - rand_float
//  10  - exit                                     44 - rand_double
//
// Intentionally omitted:
//   31, 33  - MIDI out (audio playback, irrelevant for headless CI)
//   50-59   - GUI dialog boxes (Java Swing, do not work in `nc` mode)

// ======================= Output =======================

static inline void print_int(int value) {
    register int a0 asm("a0") = value;
    register int a7 asm("a7") = 1;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

static inline void print_float(float value) {
    register float fa0 asm("fa0") = value;
    register int a7 asm("a7") = 2;
    asm volatile ("ecall" : : "f"(fa0), "r"(a7));
}

static inline void print_double(double value) {
    register double fa0 asm("fa0") = value;
    register int a7 asm("a7") = 3;
    asm volatile ("ecall" : : "f"(fa0), "r"(a7));
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

static inline float read_float(void) {
    register float fa0 asm("fa0");
    register int a7 asm("a7") = 6;
    asm volatile ("ecall" : "=f"(fa0) : "r"(a7));
    return fa0;
}

static inline double read_double(void) {
    register double fa0 asm("fa0");
    register int a7 asm("a7") = 7;
    asm volatile ("ecall" : "=f"(fa0) : "r"(a7));
    return fa0;
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

// Returns the low 32 bits of system time in milliseconds since the epoch.
// The high 32 bits are stored in *high (or ignored if NULL is not supported
// here — pass a stack variable).
static inline unsigned int get_time(unsigned int* high) {
    register unsigned int a0 asm("a0");
    register unsigned int a1 asm("a1");
    register int a7 asm("a7") = 30;
    asm volatile ("ecall" : "=r"(a0), "=r"(a1) : "r"(a7));
    if (high) *high = a1;
    return a0;
}

// Convenience wrapper that returns only the low 32 bits — sufficient for
// most "elapsed milliseconds" use cases since wraparound is ~49 days.
static inline unsigned int get_time_lo(void) {
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

// =================== Random ====================
// `stream` selects which independent RNG sequence to use (0..N).
// Each stream maintains its own seed/state inside RARS.

static inline void rng_set_seed(int stream, int seed) {
    register int a0 asm("a0") = stream;
    register int a1 asm("a1") = seed;
    register int a7 asm("a7") = 40;
    asm volatile ("ecall" : : "r"(a0), "r"(a1), "r"(a7));
}

static inline int rand_int(int stream) {
    register int a0 asm("a0") = stream;
    register int a7 asm("a7") = 41;
    asm volatile ("ecall" : "+r"(a0) : "r"(a7));
    return a0;
}

// Returns a random int in [0, upper_bound).
static inline int rand_int_range(int stream, int upper_bound) {
    register int a0 asm("a0") = stream;
    register int a1 asm("a1") = upper_bound;
    register int a7 asm("a7") = 42;
    asm volatile ("ecall" : "+r"(a0) : "r"(a1), "r"(a7));
    return a0;
}

// Returns a random float in [0.0, 1.0).
static inline float rand_float(int stream) {
    register int a0 asm("a0") = stream;
    register float fa0 asm("fa0");
    register int a7 asm("a7") = 43;
    asm volatile ("ecall" : "=f"(fa0) : "r"(a0), "r"(a7));
    return fa0;
}

// Returns a random double in [0.0, 1.0).
static inline double rand_double(int stream) {
    register int a0 asm("a0") = stream;
    register double fa0 asm("fa0");
    register int a7 asm("a7") = 44;
    asm volatile ("ecall" : "=f"(fa0) : "r"(a0), "r"(a7));
    return fa0;
}

#endif // C2RARS_RARS_IO_H
