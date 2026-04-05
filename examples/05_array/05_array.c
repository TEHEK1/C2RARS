// Example 5: Array operations
// Demonstrates working with arrays

#include <c2rars/rars_io.h>

// Find maximum in array
int find_max(int arr[], int size) {
    int max = arr[0];
    for (int i = 1; i < size; i++) {
        if (arr[i] > max) {
            max = arr[i];
        }
    }
    return max;
}

// Calculate sum of array
int array_sum(int arr[], int size) {
    int sum = 0;
    for (int i = 0; i < size; i++) {
        sum = sum + arr[i];
    }
    return sum;
}

int main() {
    int numbers[5] = {10, 25, 7, 42, 15};
    
    print_string("Array Operations Demo\n");
    print_string("=====================\n\n");
    
    // Print array
    print_string("Array: [");
    for (int i = 0; i < 5; i++) {
        print_int(numbers[i]);
        if (i < 4) {
            print_string(", ");
        }
    }
    print_string("]\n\n");
    
    // Maximum
    print_string("Maximum: ");
    print_int(find_max(numbers, 5));
    print_char('\n');
    
    // Sum
    print_string("Sum: ");
    print_int(array_sum(numbers, 5));
    print_char('\n');
    
    // Average
    print_string("Average: ");
    print_int(array_sum(numbers, 5) / 5);
    print_char('\n');
    
    return 0;
}
