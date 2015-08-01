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

void test_import_global() {
    Node *expr = parse("x + y");
    Node *glob = parse("let x=3, y=4, (+)=__builtin_add in __script");
    import_global(expr, glob);
    assert_node(glob,
                "[LET [x [INT 3]] [y [INT 4]] [+ [IDENT __builtin_add]] "
                "[APPLY [APPLY [IDENT +] [IDENT x]] [IDENT y]]]");
}

void test_starling() {
    test_import_global();
    test_parse();
    test_eval();
}
