// Example 12: Double-precision arithmetic
// Demonstrates RV32D extension support and double I/O.

#include <c2rars/rars_io.h>

// A non-trivial computation that benefits from double precision.
// This is a classic test: sum 1/n^2 for n=1..N converges to pi^2/6.
double sum_inverse_squares(int n) {
    double s = 0.0;
    for (int i = 1; i <= n; i++) {
        double x = (double)i;
        s = s + 1.0 / (x * x);
    }
    return s;
}

// Newton-Raphson square root, illustrates fadd.d/fsub.d/fmul.d/fdiv.d.
double my_sqrt(double v) {
    double x = v / 2.0;
    for (int i = 0; i < 20; i++)
        x = (x + v / x) / 2.0;
    return x;
}

int main() {
    double a = 3.5;
    double b = 2.0;

    print_string("a = ");
    print_double(a);
    print_string(", b = ");
    print_double(b);
    print_char('\n');

    print_string("a + b = ");
    print_double(a + b);
    print_char('\n');

    print_string("a * b = ");
    print_double(a * b);
    print_char('\n');

    print_string("a / b = ");
    print_double(a / b);
    print_char('\n');

    print_string("sqrt(2) ~= ");
    print_double(my_sqrt(2.0));
    print_char('\n');

    print_string("sum_{n=1..1000} 1/n^2 = ");
    print_double(sum_inverse_squares(1000));
    print_char('\n');

    int i = (int)a;
    print_string("(int)a = ");
    print_int(i);
    print_char('\n');

    double d = (double)42;
    print_string("(double)42 = ");
    print_double(d);
    print_char('\n');

    // Round-trip through float to verify fcvt.s.d / fcvt.d.s.
    float f = (float)a;
    double back = (double)f;
    print_string("(double)(float)a = ");
    print_double(back);
    print_char('\n');

    return 0;
}
