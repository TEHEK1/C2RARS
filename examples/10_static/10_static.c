// Example 10: Global and static variables
// Demonstrates persistent state across function calls using:
//   - global initialized variables (.data / .sdata)
//   - global zero-initialized variables (.bss / .sbss via .comm)
//   - function-scope static variables (GCC-mangled names like name.0)

#include <c2rars/rars_io.h>

int g_initialized = 1;
int g_zero;

int fibonacci() {
    static int first = 0;
    static int second = 1;
    int out = first + second;
    first = second;
    second = out;
    return out;
}

int main() {
    print_string("Globals before:\n");
    print_int(g_initialized);
    print_string("\n");
    print_int(g_zero);
    print_string("\n");

    g_zero = g_initialized + 41;

    print_string("Globals after:\n");
    print_int(g_initialized);
    print_string("\n");
    print_int(g_zero);
    print_string("\n");

    print_string("First 10 Fibonacci numbers:\n");
    for (int i = 0; i < 10; i++) {
        print_int(fibonacci());
        print_string("\n");
    }

    return 0;
}
