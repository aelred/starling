#include "node.h"

Node *eval(const char *s);

void repl();

Node *parse(const char *s);

Node *eval_expr(Node *expr);

void expr_string(Node *expr, char *s, size_t n);
