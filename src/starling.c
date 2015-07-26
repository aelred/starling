#include <stdio.h>
#include "starling.h"
#include "util.h"


// Evaluate a string expression and return the resulting object
struct Object eval(const char *expr) {
}


// Create a string representation of an object
void object_str(const struct Object obj, char **str) {
    *str = "<Object>";
}


// Run a read-evaluate-print loop
void repl() {
    while (1) {
        printf(">>> ");
        char *line = NULL;
        size_t size;

        if (getline(&line, &size, stdin) == -1 || is_empty(line)) {
            // Stop when no more input is provided
            break;
        } else {
            // Evaluate user input and print as a string
            struct Object result = eval(line);
            char *res_str = NULL;
            object_str(result, &res_str);
            puts(res_str);
        }
    }
}
