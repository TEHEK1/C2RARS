// Example 2: Arithmetic operations
// Demonstrates calculations and number output

#include <c2rars/rars_io.h>

int main() {
    int a = 15;
    int b = 27;
    
    print_string("a = ");
    print_int(a);
    print_string(", b = ");
    print_int(b);
    print_char('\n');
    
    print_string("a + b = ");
    print_int(a + b);
    print_char('\n');
    
    print_string("a - b = ");
    print_int(a - b);
    print_char('\n');
    
    print_string("a * b = ");
    print_int(a * b);
    print_char('\n');
    
    return 0;
}
