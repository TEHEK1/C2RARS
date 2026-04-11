// Example 9: Floating-point arithmetic
// Demonstrates RV32F extension support and float I/O

#include <c2rars/rars_io.h>

float circle_area(float radius) {
    return 3.14159f * radius * radius;
}

int main() {
    float a = 3.5f;
    float b = 2.0f;

    print_string("a = ");
    print_float(a);
    print_string(", b = ");
    print_float(b);
    print_char('\n');

    print_string("a + b = ");
    print_float(a + b);
    print_char('\n');

    print_string("a * b = ");
    print_float(a * b);
    print_char('\n');

    print_string("a / b = ");
    print_float(a / b);
    print_char('\n');

    float r = 5.0f;
    print_string("Area of circle (r=");
    print_float(r);
    print_string("): ");
    print_float(circle_area(r));
    print_char('\n');

    int i = (int)a;
    print_string("(int)a = ");
    print_int(i);
    print_char('\n');

    float f = (float)42;
    print_string("(float)42 = ");
    print_float(f);
    print_char('\n');

    return 0;
}
