#include "node.h"

#define assert__(x) for ( ; !(x) ; assert(x) )

// Return whether given string contains only whitespace
int is_empty(const char *);

// Return whether given string represents an infix identifier
int is_infix(const char *s);

// Test that the node has the given string representation
void assert_node(Node *node, const char *expected);
