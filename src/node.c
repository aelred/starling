#include <stdarg.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "node.h"
#include "parser.h"
#include "string.h"

Node *node(int type) {
    Node *n = malloc(sizeof(Node));
    n->type = type;
    return n;
}

static void node_str_(Node *node, string *s);

static void bind_str(vector *binds, string *s) {
    Bind *bind;
    int i;
    for (i=0; i < binds->size; i++) {
        bind = (Bind *)vector_get(binds, i);
        if (bind->is_enum) {
            string_append(s, "%s ", bind->name);
        } else {
            string_append(s, "[%s ", bind->name);
            node_str_(bind->expr, s);
            string_append(s, "] ");
        }
    }
}

static void node_str_(Node *node, string *s) {
    const char *name = token_name(node->type);
    int i;

    string_append(s, "[%s ", name);

    switch (node->type) {
        case BOOL:
        case INT:
            string_append(s, "%d", node->intval);
            break;
        case STRING:
        case CHAR:
        case IMPORT:
        case ACCESSOR:
            string_append(s, node->strval);
            break;
        case IDENT:
            string_append(s, node->ident.name);
            break;
        case APPLY:
            node_str_(node->apply.optor, s);
            string_append(s, " ");
            node_str_(node->apply.opand, s);
            break;
        case OBJECT:
            bind_str(node->elems, s);
            break;
        case EXPORT:
            for (i=0; i < node->elems->size; i++) {
                string_append(s, "%s ", vector_get(node->elems, i));
            }
            break;
        case STRICT:
            node_str_(node->expr, s);
            break;
        case LET:
            bind_str(node->let.binds, s);
            node_str_(node->let.expr, s);
            break;
        case LAMBDA:
            string_append(s, "%s ", node->lambda.param);
            node_str_(node->lambda.expr, s);
            break;
        case IF:
            node_str_(node->if_.pred, s);
            string_append(s, " ");
            node_str_(node->if_.cons, s);
            string_append(s, " ");
            node_str_(node->if_.alt, s);
            break;
        default:
            string_append(s, "UNKNOWN");
    }

    string_append(s, "]");
}

const int INITIAL_SIZE = 128;

char *node_str(Node *node) {
    string *s = string_new();
    node_str_(node, s);
    return s->elems;
}

// Pre-order traversal
void node_walk(Node **n, void (func)(Node **)) {
    func(n);
    int i;

    switch ((*n)->type) {
        case OBJECT:
            for (i = 0; i < (*n)->elems->size; i++) {
                node_walk(&(((Bind *)vector_get((*n)->elems, i))->expr), func);
            }
        case STRICT:
            node_walk(&((*n)->expr), func);
            break;
        case APPLY:
            node_walk(&((*n)->apply.optor), func);
            node_walk(&((*n)->apply.opand), func);
            break;
        case LET:
            for (i = 0; i < (*n)->let.binds->size; i++) {
                node_walk(&(((Bind *)vector_get((*n)->let.binds, i))->expr), func);
            }
            node_walk(&((*n)->let.expr), func);
            break;
        case LAMBDA:
            node_walk(&((*n)->lambda.expr), func);
            break;
        case IF:
            node_walk(&((*n)->if_.pred), func);
            node_walk(&((*n)->if_.cons), func);
            node_walk(&((*n)->if_.alt), func);
            break;
    }
}
