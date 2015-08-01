#include "node.h"

#define assert__(x) for ( ; !(x) ; assert(x) )

int is_empty(const char *);

void assert_node(Node *node, char *expected);
