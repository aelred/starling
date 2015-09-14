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

Node *eval(const char *s) {
    return eval_expr(parse(s));
}

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
            char *res_str = node_code(result);
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
    // Remove unused definitions
    prune_unused(&new_expr);
    return new_expr;
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
            (*node)->ident.def = NULL;
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

void link_identifiers(Node *expr) {
    env = vector_new();
    node_walk(&expr, push_env, pop_env);
    vector_free(env);
}

// Calculate and record dependencies of an expression
static vector *calc_dependencies(Node *expr) {
    if (expr->dependencies != NULL) return expr->dependencies;

    vector *deps = vector_new();
    expr->dependencies = deps;

    switch (expr->type) {
        case STRICT:
            vector_join(deps, calc_dependencies(expr->expr));
            break;
        case IDENT:
            if (expr->ident.def != NULL) {
                vector_push(deps, expr->ident.def);
                vector_join(deps, calc_dependencies(expr->ident.def->expr));
            }
            break;
        case APPLY:
            vector_join(deps, calc_dependencies(expr->apply.optor));
            vector_join(deps, calc_dependencies(expr->apply.opand));
            break;
        case LET:
            vector_join(deps, calc_dependencies(expr->let.expr));
            break;
        case LAMBDA:
            vector_join(deps, calc_dependencies(expr->lambda.expr));
            break;
        case IF:
            vector_join(deps, calc_dependencies(expr->if_.pred));
            vector_join(deps, calc_dependencies(expr->if_.cons));
            vector_join(deps, calc_dependencies(expr->if_.alt));
            break;
    }

    return deps;
}

static vector *dependencies;

static void remove_unused(Node **expr) {
    Bind *bind;
    if ((*expr)->type == LET) {
        for (int i=0; i < (*expr)->let.binds->size; i++) {
            bind = vector_get((*expr)->let.binds, i);

            // Lookup binding in used dependencies
            int found = 0;
            for (int j=0; j < dependencies->size; j++) {
                if (bind == vector_get(dependencies, j)) {
                    found = 1;
                    break;
                }
            }
            if (!found) {
                // Delete this binding
                vector_remove((*expr)->let.binds, i);
                i--;
            }
        }

        // If no bindings left, delete entire let expression
        if ((*expr)->let.binds->size == 0) {
            *expr = (*expr)->let.expr;
        }
    }
}

void prune_unused(Node **expr) {
    dependencies = calc_dependencies(*expr);
    node_walk(expr, remove_unused, no_action);
}
