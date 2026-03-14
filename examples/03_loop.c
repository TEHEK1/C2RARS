// Example 3: Loop demonstration
// Shows for/while loops working with C2RARS

#include <c2rars/rars_io.h>

int main() {
    print_string("Countdown from 10:\n");
    
    // For loop
    for (int i = 10; i >= 1; i--) {
        print_int(i);
        print_string("... ");
    }
    
    print_string("\nLiftoff!\n");
    
    // While loop - sum from 1 to 10
    print_string("\nSum from 1 to 10:\n");
    int sum = 0;
    int n = 1;
    
    while (n <= 10) {
        sum = sum + n;
        n++;
    }
    
    print_string("Result: ");
    print_int(sum);
    print_char('\n');
    
    return 0;
}
