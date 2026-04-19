// Example 13: RARS random number generator syscalls (40-44).
// With a fixed seed the output is fully deterministic — perfect for CI.

#include <c2rars/rars_io.h>

int main() {
    // Stream 0 with a fixed seed makes the run reproducible.
    rng_set_seed(0, 42);

    print_string("rand_int:\n");
    for (int i = 0; i < 3; i++) {
        print_int(rand_int(0));
        print_char('\n');
    }

    print_string("rand_int_range(100):\n");
    for (int i = 0; i < 3; i++) {
        print_int(rand_int_range(0, 100));
        print_char('\n');
    }

    print_string("rand_float [0,1):\n");
    for (int i = 0; i < 3; i++) {
        print_float(rand_float(0));
        print_char('\n');
    }

    print_string("rand_double [0,1):\n");
    for (int i = 0; i < 3; i++) {
        print_double(rand_double(0));
        print_char('\n');
    }

    return 0;
}
