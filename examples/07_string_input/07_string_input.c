// Example 7: String input and extended I/O
// Demonstrates read_string, print_int_hex, and other new syscalls

#include <c2rars/rars_io.h>

int main() {
    char name[64];

    print_string("Enter your name: ");
    read_string(name, 64);

    print_string("Hello, ");
    print_string(name);

    int num = read_int();
    print_string("You entered: ");
    print_int(num);
    print_char('\n');

    print_string("Hex: ");
    print_int_hex(num);
    print_char('\n');

    print_string("Bin: ");
    print_int_bin(num);
    print_char('\n');

    return 0;
}
