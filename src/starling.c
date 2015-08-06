#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "starling.h"
#include "util.h"
#include "lexer.h"
#include "parser.h"
#include "node.h"
#include "string.h"

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
        string *line = string_new();
        int c;

        // Read input until a newline
        c = getchar();
        while (c != '\n' && c != EOF) {
            string_push(line, c);
            c = getchar();
        }

        if (is_empty(line->elems)) {
            // Stop when no more input is provided
            break;
        } else {
            // Evaluate user input and print as a string
            Node *result = eval(line->elems);
            char *res_str = expr_string(result);
            puts(res_str);
            free(res_str);
        }
    }
}

static Node *load_module(const char *name) {
    size_t len = strlen(MODULES) + strlen(name) + strlen(STAREXT) + 1;
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
    // Link identifiers to definitions
    link_identifiers(new_expr);
    return new_expr;
}

char *expr_string(Node *expr) {
    return node_code(expr);
}

static Node *sub_expr;

static void no_action(__attribute__ ((unused)) Node **node) {
}

static void sub_global(Node **node) {
    if ((*node)->type == IDENT && !strcmp((*node)->strval, SCRIPT)) {
        *node = sub_expr;
    }
}

void import_global(Node *expr, Node *global) {
    sub_expr = expr;
    node_walk(&global, sub_global, no_action);
}

static vector *env;

// Push any definitions onto environment
static void push_env(Node **node) {
    Bind *bind;

    switch ((*node)->type) {
        case LET:
            // Push all definitions in let expression
            vector_join(env, (*node)->let.binds);
            break;
        case IDENT:
            // Look up identifier in environment
            for (int i = env->size-1; i >= 0; i --) {
                bind = vector_get(env, i);
                if (!strcmp((*node)->ident.name, bind->name)) {
                    (*node)->ident.def = bind;
                    vector_push(bind->uses, *node);
                    break;
                }
            }
            break;
    }
}

// Pop any pushed definitions
static void pop_env(Node **node) {
    if ((*node)->type == LET) {
        for (int i=0; i < (*node)->let.binds->size; i++) {
            vector_pop(env);
        }
    }
}

// Link all identifiers to their definitions
void link_identifiers(Node *expr) {
    env = vector_new();
    node_walk(&expr, push_env, pop_env);
    vector_free(env);
}
