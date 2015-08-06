#include <assert.h>
#include <string.h>
#include "test.h"
#include "starling.h"
#include "parser.h"
#include "util.h"
#include "vector.h"

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

static void test_link_identifiers(void) {
    Node *expr = parse("let x=1 in (let x=2 in x) x");
    Bind *def1 = (Bind *)vector_get(expr->let.binds, 0);
    Node *use1 = expr->let.expr->apply.opand;
    Bind *def2 = (Bind *)vector_get(expr->let.expr->apply.optor->let.binds, 0);
    Node *use2 = expr->let.expr->apply.optor->let.expr;
    link_identifiers(expr);
    // Check definitions of x points to correct usage
    assert(!strcmp(def1->name, "x"));
    assert(def1->uses->size == 1);
    assert(vector_get(def1->uses, 0) == use1);
    assert(!strcmp(def2->name, "x"));
    assert(def2->uses->size == 1);
    assert(vector_get(def2->uses, 0) == use2);
    assert(def1 != def2);
    // Check usages of x points to correct definition
    assert(use1->ident.def == def1);
    assert(use2->ident.def == def2);
    assert(use1 != use2);
}

void test_starling() {
    test_link_identifiers();
    test_import_global();
    test_parse();
    test_eval();
}
