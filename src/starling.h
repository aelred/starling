#include "node.h"

// Evaluate the given starling string and return the result
Node *eval(const char *s);

// Run a read-evaluate-print-loop
void repl(void);

// Parse the given starling string and return a syntax tree
Node *parse(const char *s);

// Evaluate the given syntax tree
Node *eval_expr(Node *expr);

// Include global definitions in the given syntax tree
void import_global(Node *expr, Node *global);

// Link identifiers to their definitions in the syntax tree
void link_identifiers(Node *expr);

// Prune any unused definitions from the given syntax tree
void prune_unused(Node **expr);
