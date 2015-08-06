#include "node.h"

Node *eval(const char *s);

void repl(void);

Node *parse(const char *s);

Node *eval_expr(Node *expr);

char *expr_string(Node *expr);

void import_global(Node *expr, Node *global);

void link_identifiers(Node *expr);
