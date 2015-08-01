#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "starling.h"
#include "util.h"
#include "lexer.h"
#include "parser.h"
#include "node.h"

const char *SCRIPT = "__script";

const char *MODULES = "modules/";
const char *STAREXT = ".star";

// Evaluate a string expression and return the resulting object
Node *eval(const char *s) {
    return eval_expr(parse(s));
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

static Node *load_module(char *name) {
    int len = strlen(MODULES) + strlen(name) + strlen(STAREXT) + 1;
    char *path = malloc(sizeof(char) * len);
    snprintf(path, len, "%s%s%s", MODULES, name, STAREXT);
    yyin = fopen(path, "r");
    YY_BUFFER_STATE buf = yy_create_buffer(yyin, YY_BUF_SIZE);
    yy_switch_to_buffer(buf);
    yyparse();
    yy_delete_buffer(buf);
    fclose(yyin);
    free(path);
    return parser_result;
}

Node *parse(const char *s) {
    YY_BUFFER_STATE buf = yy_scan_string(s);
    yyparse();
    yy_delete_buffer(buf);
    return parser_result;
}

Node *eval_expr(Node *expr) {
    // Add standard library
    Node *new_expr = load_module("lib");
    import_global(expr, new_expr);
    return new_expr;
}

char *expr_string(Node *expr) {
    return node_str(expr);
}

static Node *sub_expr;

static void sub_global(Node **node) {
    if ((*node)->type == IDENT && !strcmp((*node)->strval, SCRIPT)) {
        *node = sub_expr;
    }
}

void import_global(Node *expr, Node *global) {
    sub_expr = expr;
    node_walk(&global, sub_global);
}
