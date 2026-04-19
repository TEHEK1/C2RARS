#ifndef C2RARS_RARS_IO_H
#define C2RARS_RARS_IO_H

// RARS syscall wrappers for C2RARS, dual-platform.
//
//   - print_int_hex            -> "0x" + 8 lowercase hex digits, zero-padded
//   - print_int_bin            -> 32 binary digits, zero-padded, no prefix
//   - print_float/double       -> Java Float/Double.toString
//   - rand_*                   -> Java Random LCG (seed*0x5DEECE66D + 0xB)
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

#if defined(__C2RARS__)

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

static inline void* sbrk(int num_bytes) {
    register int a0 asm("a0") = num_bytes;
    register int a7 asm("a7") = 9;
    asm volatile ("ecall" : "+r"(a0) : "r"(a7));
    return (void*)a0;
}

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

static inline void rars_exit(int code) {
    register int a0 asm("a0") = code;
    register int a7 asm("a7") = 17;
    asm volatile ("ecall" : : "r"(a0), "r"(a7));
}

// Returns the low 32 bits of system time in milliseconds since the epoch.
// The high 32 bits are stored in *high (pass NULL to ignore — but most callers
// can simply use get_time_lo()).
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

// `stream` selects an independent RNG sequence (0..N); each stream keeps its
// own seed/state inside RARS.

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

static inline float rand_float(int stream) {
    register int a0 asm("a0") = stream;
    register float fa0 asm("fa0");
    register int a7 asm("a7") = 43;
    asm volatile ("ecall" : "=f"(fa0) : "r"(a0), "r"(a7));
    return fa0;
}

static inline double rand_double(int stream) {
    register int a0 asm("a0") = stream;
    register double fa0 asm("fa0");
    register int a7 asm("a7") = 44;
    asm volatile ("ecall" : "=f"(fa0) : "r"(a0), "r"(a7));
    return fa0;
}

#else // !__C2RARS__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#if defined(_WIN32)
  #include <windows.h>
  #include <io.h>
#else
  #include <unistd.h>
  #include <sys/time.h>
  #include <fcntl.h>
#endif

// Java Double.toString / Float.toString

static inline void __c2rars_print_double_java(double value, int max_prec) {
    if (value != value) { fputs("NaN", stdout); return; }
    if (value > 0 && value > 1.7976931348623157e308) { fputs("Infinity", stdout); return; }
    if (value < 0 && value < -1.7976931348623157e308) { fputs("-Infinity", stdout); return; }

    char buf[64];
    for (int p = 1; p <= max_prec; p++) {
        snprintf(buf, sizeof buf, "%.*g", p, value);
        double back = strtod(buf, NULL);
        if (back == value) break;
    }

    int has_dot_or_exp = 0;
    for (const char* q = buf; *q; q++) {
        if (*q == '.' || *q == 'e' || *q == 'E') { has_dot_or_exp = 1; break; }
    }
    if (!has_dot_or_exp) {
        size_t n = strlen(buf);
        if (n + 2 < sizeof buf) {
            buf[n] = '.'; buf[n+1] = '0'; buf[n+2] = '\0';
        }
    }
    fputs(buf, stdout);
}

static inline void __c2rars_print_float_java(float value) {
    if (value != value) { fputs("NaN", stdout); return; }
    if (value > 0 && value > 3.4028235e38f) { fputs("Infinity", stdout); return; }
    if (value < 0 && value < -3.4028235e38f) { fputs("-Infinity", stdout); return; }

    char buf[64];
    for (int p = 1; p <= 9; p++) {
        snprintf(buf, sizeof buf, "%.*g", p, (double)value);
        float back = strtof(buf, NULL);
        if (back == value) break;
    }
    int has_dot_or_exp = 0;
    for (const char* q = buf; *q; q++) {
        if (*q == '.' || *q == 'e' || *q == 'E') { has_dot_or_exp = 1; break; }
    }
    if (!has_dot_or_exp) {
        size_t n = strlen(buf);
        if (n + 2 < sizeof buf) {
            buf[n] = '.'; buf[n+1] = '0'; buf[n+2] = '\0';
        }
    }
    fputs(buf, stdout);
}

static inline void print_int(int value) { printf("%d", value); }

static inline void print_float(float value) { __c2rars_print_float_java(value); }

static inline void print_double(double value) { __c2rars_print_double_java(value, 17); }

static inline void print_string(const char* str) { fputs(str, stdout); }

static inline void print_char(char c) { putchar((unsigned char)c); }

static inline void print_int_hex(int value) {
    printf("0x%08x", (unsigned int)value);
}

static inline void print_int_bin(int value) {
    char buf[33];
    unsigned int v = (unsigned int)value;
    for (int i = 0; i < 32; i++)
        buf[31 - i] = (char)('0' + ((v >> i) & 1u));
    buf[32] = '\0';
    fputs(buf, stdout);
}

static inline void print_int_unsigned(unsigned int value) {
    printf("%u", value);
}

static inline int read_int(void) {
    int x = 0;
    if (scanf("%d", &x) != 1) return 0;
    return x;
}

static inline float read_float(void) {
    float x = 0.0f;
    if (scanf("%f", &x) != 1) return 0.0f;
    return x;
}

static inline double read_double(void) {
    double x = 0.0;
    if (scanf("%lf", &x) != 1) return 0.0;
    return x;
}

static inline char read_char(void) {
    int c = getchar();
    return c == EOF ? '\0' : (char)c;
}

static inline void read_string(char* buffer, int max_length) {
    if (max_length <= 0 || buffer == NULL) return;
    if (fgets(buffer, max_length, stdin) == NULL) {
        buffer[0] = '\0';
        return;
    }
    size_t n = strlen(buffer);
    if (n > 0 && buffer[n - 1] == '\n') buffer[n - 1] = '\0';
}

#if defined(_WIN32)
static inline void* sbrk(int num_bytes) { return malloc((size_t)num_bytes); }
#endif

static inline int file_open(const char* filename, int flags) {
#if defined(_WIN32)
    return _open(filename, flags);
#else
    return open(filename, flags, 0644);
#endif
}

static inline int file_read(int fd, char* buffer, int length) {
#if defined(_WIN32)
    return _read(fd, buffer, length);
#else
    return (int)read(fd, buffer, (size_t)length);
#endif
}

static inline int file_write(int fd, const char* buffer, int length) {
#if defined(_WIN32)
    return _write(fd, buffer, length);
#else
    return (int)write(fd, buffer, (size_t)length);
#endif
}

static inline void file_close(int fd) {
#if defined(_WIN32)
    _close(fd);
#else
    close(fd);
#endif
}

static inline void rars_exit(int code) { exit(code); }

static inline unsigned int get_time(unsigned int* high) {
#if defined(_WIN32)
    unsigned long long ms = (unsigned long long)GetTickCount64();
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    unsigned long long ms =
        (unsigned long long)tv.tv_sec * 1000ULL + (unsigned long long)tv.tv_usec / 1000ULL;
#endif
    if (high) *high = (unsigned int)(ms >> 32);
    return (unsigned int)ms;
}

static inline unsigned int get_time_lo(void) { return get_time(NULL); }

static inline void rars_sleep(int milliseconds) {
#if defined(_WIN32)
    Sleep((unsigned)milliseconds);
#else
    if (milliseconds > 0) usleep((unsigned)milliseconds * 1000u);
#endif
}

// Java-compatible LCG

#define __C2RARS_RNG_MAX_STREAMS 64
static unsigned long long __c2rars_rng_state[__C2RARS_RNG_MAX_STREAMS];
static int __c2rars_rng_initialised[__C2RARS_RNG_MAX_STREAMS];

static inline unsigned long long __c2rars_rng_default_seed(int stream) {
    (void)stream;
    return ((unsigned long long)0 ^ 0x5DEECE66DULL) & ((1ULL << 48) - 1);
}

static inline int __c2rars_rng_next(int stream, int bits) {
    if (stream < 0 || stream >= __C2RARS_RNG_MAX_STREAMS) stream = 0;
    if (!__c2rars_rng_initialised[stream]) {
        __c2rars_rng_state[stream] = __c2rars_rng_default_seed(stream);
        __c2rars_rng_initialised[stream] = 1;
    }
    __c2rars_rng_state[stream] =
        (__c2rars_rng_state[stream] * 0x5DEECE66DULL + 0xBULL) & ((1ULL << 48) - 1);
    return (int)(__c2rars_rng_state[stream] >> (48 - bits));
}

static inline void rng_set_seed(int stream, int seed) {
    if (stream < 0 || stream >= __C2RARS_RNG_MAX_STREAMS) stream = 0;
    __c2rars_rng_state[stream] =
        ((unsigned long long)(unsigned int)seed ^ 0x5DEECE66DULL) & ((1ULL << 48) - 1);
    __c2rars_rng_initialised[stream] = 1;
}

static inline int rand_int(int stream) { return __c2rars_rng_next(stream, 32); }

static inline int rand_int_range(int stream, int upper_bound) {
    if (upper_bound <= 0) return 0;
    if ((upper_bound & -upper_bound) == upper_bound) {
        long long r = (long long)upper_bound * (long long)__c2rars_rng_next(stream, 31);
        return (int)(r >> 31);
    }
    int bits, val;
    do {
        bits = __c2rars_rng_next(stream, 31);
        val = bits % upper_bound;
    } while (bits - val + (upper_bound - 1) < 0);
    return val;
}

static inline float rand_float(int stream) {
    return (float)__c2rars_rng_next(stream, 24) / (float)(1 << 24);
}

static inline double rand_double(int stream) {
    long long hi = (long long)__c2rars_rng_next(stream, 26) << 27;
    long long lo = (long long)__c2rars_rng_next(stream, 27);
    return (double)(hi + lo) / (double)(1LL << 53);
}

#endif // __C2RARS__

#endif // C2RARS_RARS_IO_H
