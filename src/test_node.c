#include <assert.h>
#include <stdio.h>
#include "test.h"
#include "parser.h"
#include "node.h"
#include "starling.h"
#include "util.h"

static int all_ints[10];
static int count = 0;

static void record_ints(Node **n) {
    if ((*n)->type == INT) {
	// Track every integer
	all_ints[count++] = (*n)->intval;
    }
}

static void replace_bool(Node **n) {
    if ((*n)->type == INT) {
	// Transform every integer into a boolean
	Node *new_node = node(BOOL);
	new_node->intval = 0;
	*n = new_node;
    }
}

static void test_node_walk(void) {
    Node *node = parse("let x = 10 + 20 in {x=30}");
    node_walk(&node, record_ints, replace_bool);
    // Make sure integers were counted correctly
    assert__(count == 3) { printf("%d != 3\n", count); };
    assert(all_ints[0] == 10);
    assert(all_ints[1] == 20);
    assert(all_ints[2] == 30);
    // Make sure integers are all booleans
    assert_node(node, 
		"[LET [x [APPLY [APPLY [IDENT +] [BOOL 0]] [BOOL 0]]] "
		"[OBJECT [x [BOOL 0]] ]]");
}

void test_node() {
    test_node_walk();
}
