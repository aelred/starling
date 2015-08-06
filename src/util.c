#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <malloc.h>
#include "node.h"
#include "starling.h"
#include "util.h"

// Test if an entire string is only whitespace
int is_empty(const char *s) {
    while (*s != '\0') {
        if (!isspace((unsigned char)*s)) return 0;
        s++;
    }
    
    return 1;
}

// Test if node matches string representation
void assert_node(Node *node, const char *expected) {
    char *str = node_str(node);
    assert__(!strcmp(str, expected)) {
        printf("%s != %s\n", str, expected);
    }
    free(str);
}
