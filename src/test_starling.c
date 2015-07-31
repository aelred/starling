#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "starling.h"
#include "parser.h"

#define assert__(x) for ( ; !(x) ; assert(x) )

void assert_node(Node *node, char *expected) {
    size_t n = 100;
    char str[n];
    expr_string(node, str, n);
    assert__(!strcmp(str, expected)) {
        printf("%s != %s\n", str, expected);
    }
}

void test_eval() {
    assert(eval("1")->type == INT);
    assert(eval("2*3")->type == INT);
}

void test_parse() {
    assert_node(parse("30"), "[INT 30]");
    assert_node(parse("False"), "[BOOL 0]");
    assert_node(parse("let x=1 in x"), "[LET [x [INT 1]] [IDENT x]]");
}

void test_starling() {
    test_eval();
    test_parse();
}
