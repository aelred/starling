#include <stdarg.h>
#include <stdio.h>
#include <malloc.h>
#include "node.h"
#include "parser.h"

Node *node(int type) {
    Node *n = malloc(sizeof(Node));
    n->type = type;
    return n;
}

void print(char **s, size_t *n, const char *format, ...) {
    va_list argptr;
    va_start(argptr, format);
    int written = vsnprintf(*s, *n, format, argptr);
    va_end(argptr);
    *s += written;
    *n -= written;
}

static void node_str_(Node *node, char **s, size_t *n);

void bind_str(vector *binds, char **s, size_t *n) {
    Bind *bind;
    int i;
    for (i=0; i < binds->size; i++) {
        bind = (Bind *)vector_get(binds, i);
        if (bind->is_enum) {
            print(s, n, "%s ", bind->name);
        } else {
            print(s, n, "[%s ", bind->name);
            node_str_(bind->expr, s, n);
            print(s, n, "] ");
        }
    }
}

static void node_str_(Node *node, char **s, size_t *n) {
    const char *name = token_name(node->type);
    int i;

    print(s, n, "[%s ", name);

    switch (node->type) {
        case BOOL:
        case INT:
            print(s, n, "%d", node->intval);
            break;
        case IDENT:
        case STRING:
        case CHAR:
        case IMPORT:
        case ACCESSOR:
            print(s, n, node->strval);
            break;
        case APPLY:
            node_str_(node->apply.optor, s, n);
            print(s, n, " ");
            node_str_(node->apply.opand, s, n);
            break;
        case OBJECT:
            bind_str(node->elems, s, n);
            break;
        case EXPORT:
            for (i=0; i < node->elems->size; i++) {
                print(s, n, "%s ", vector_get(node->elems, i));
            }
            break;
        case STRICT:
            node_str_(node->expr, s, n);
            break;
        case LET:
            bind_str(node->let.binds, s, n);
            node_str_(node->let.expr, s, n);
            break;
        case LAMBDA:
            print(s, n, "%s ", node->lambda.param);
            node_str_(node->lambda.expr, s, n);
            break;
        case IF:
            node_str_(node->if_.pred, s, n);
            print(s, n, " ");
            node_str_(node->if_.cons, s, n);
            print(s, n, " ");
            node_str_(node->if_.alt, s, n);
            break;
        default:
            print(s, n, "UNKNOWN");
    }

    print(s, n, "]");
}

void node_str(Node *node, char *s, size_t n) {
    node_str_(node, &s, &n);
}
