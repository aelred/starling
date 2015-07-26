#include <ctype.h>


// Test if an entire string is only whitespace
int is_empty(const char *s) {
    while (*s != '\0') {
        if (!isspace((unsigned char)*s)) return 0;
        s++;
    }
    
    return 1;
}
