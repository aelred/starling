#include "node.h"

#define assert__(x) for ( ; !(x) ; assert(x) )

int is_empty(const char *);

int is_infix(const char *s);

void assert_node(Node *node, const char *expected);
