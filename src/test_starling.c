#include <assert.h>
#include "test.h"
#include "starling.h"
#include "parser.h"
#include "util.h"

static void test_eval(void) {
    assert(eval("1")->type == INT);
    assert(eval("2*3")->type == INT);
}

static void test_parse(void) {
    assert_node(parse("30"), "[INT 30]");
    assert_node(parse("False"), "[BOOL 0]");
    assert_node(parse("let x=1 in x"), "[LET [x [INT 1]] [IDENT x]]");
}

static void test_import_global(void) {
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
