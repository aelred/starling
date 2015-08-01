#include "node.h"

Node *eval(const char *s);

void repl();

Node *parse(const char *s);

Node *eval_expr(Node *expr);

char *expr_string(Node *expr);
