#include <assert.h>
#include "starling.h"
#include "parser.h"
#include "util.h"

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
