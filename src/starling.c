#include <stdio.h>
#include <malloc.h>
#include "starling.h"
#include "util.h"
#include "lexer.h"
#include "parser.h"
#include "node.h"

// Evaluate a string expression and return the resulting object
Node *eval(const char *s) {
    return parse(s);
}

// Run a read-evaluate-print loop
void repl() {
    while (1) {
        printf(">>> ");
        char *line = NULL;
        size_t size;

        if (getline(&line, &size, stdin) == -1 || is_empty(line)) {
            // Stop when no more input is provided
            break;
        } else {
            // Evaluate user input and print as a string
            Node *result = eval(line);
            char *res_str = expr_string(result);
            puts(res_str);
            free(res_str);
        }
    }
}

Node *parse(const char *s) {
    YY_BUFFER_STATE buf = yy_scan_string(s);
    yyparse();
    yy_delete_buffer(buf);
    return result;
}

Node *eval_expr(Node *expr) {
}

void expr_string(Node *expr, char *s, size_t n) {
    node_str(expr, s, n);
}
