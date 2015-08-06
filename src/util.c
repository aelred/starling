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

// Test if an identifier is infix
int is_infix(const char *s) {
    switch (s[0]) {
        case '-':
        case '+':
        case '*':
        case '/':
        case '=':
        case '<':
        case '>':
        case '?':
        case ':':
        case '@':
        case '!':
        case '&':
        case '|':
            return 1;
        default:
            if (!strcmp(s, "and")) return 1;
            if (!strcmp(s, "or")) return 1;
            if (!strcmp(s, "mod")) return 1;
            if (!strcmp(s, "pow")) return 1;
            if (!strcmp(s, "has")) return 1;
    }

    return 0;
}

// Test if node matches string representation
void assert_node(Node *node, const char *expected) {
    char *str = node_str(node);
    assert__(!strcmp(str, expected)) {
        printf("%s != %s\n", str, expected);
    }
    free(str);
}
