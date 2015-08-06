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
    n->dependencies = NULL;
    return n;
}

const int INITIAL_SIZE = 128;

static void node_str_(Node *node, string *s);

static void bind_str(vector *binds, string *s) {
    Bind *bind;
    int i;
    for (i=0; i < binds->size; i++) {
        bind = (Bind *)vector_get(binds, i);
        string_append(s, "[%s ", bind->name);
        node_str_(bind->expr, s);
        string_append(s, "] ");
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

char *node_str(Node *node) {
    string *s = string_new();
    node_str_(node, s);
    return s->elems;
}

static void node_code_(Node *node, string *s);

static void bind_code(vector *binds, string *s) {
    Bind *bind;
    int i;
    for (i=0; i < binds->size; i++) {
        bind = (Bind *)vector_get(binds, i);
        string_append(s, "%s = ", bind->name);
        node_code_(bind->expr, s);
        if (i < binds->size-1) string_append(s, ", ");
    }
}

static void node_code_(Node *node, string *s) {
    int i;

    switch (node->type) {
        case BOOL:
            if (node->intval)
                string_append(s, "True");
            else
                string_append(s, "False");
            break;
        case INT:
            string_append(s, "%d", node->intval);
            break;
        case STRING:
            string_append(s, "\"%s\"", node->strval);
            break;
        case CHAR:
            string_append(s, "'%s'", node->strval);
            break;
        case IMPORT:
            string_append(s, "import %s", node->strval);
            break;
        case ACCESSOR:
            string_append(s, "(.%s)", node->strval);
            break;
        case IDENT:
            string_append(s, node->ident.name);
            break;
        case APPLY:
            string_append(s, "(");
            node_code_(node->apply.optor, s);
            string_append(s, " ");
            node_code_(node->apply.opand, s);
            string_append(s, ")");
            break;
        case OBJECT:
            string_append(s, "{");
            bind_code(node->elems, s);
            string_append(s, "}");
            break;
        case EXPORT:
            string_append(s, "(export ");
            for (i=0; i < node->elems->size; i++) {
                string_append(s, "%s ", vector_get(node->elems, i));
            }
            string_append(s, ")");
            break;
        case STRICT:
            string_append(s, "(strict ");
            node_code_(node->expr, s);
            string_append(s, ")");
            break;
        case LET:
            string_append(s, "(let ");
            bind_code(node->let.binds, s);
            string_append(s, " in ");
            node_code_(node->let.expr, s);
            string_append(s, ")");
            break;
        case LAMBDA:
            string_append(s, "(%s ", node->lambda.param);
            string_append(s, " -> ");
            node_code_(node->lambda.expr, s);
            string_append(s, ")");
            break;
        case IF:
            string_append(s, "(if ");
            node_code_(node->if_.pred, s);
            string_append(s, " then ");
            node_code_(node->if_.cons, s);
            string_append(s, " else ");
            node_code_(node->if_.alt, s);
            string_append(s, ")");
            break;
        default:
            string_append(s, "UNKNOWN");
    }
}

char *node_code(Node *node) {
    string *s = string_new();
    node_code_(node, s);
    return s->elems;
}

void node_walk(Node **n, void (pre)(Node **), void (post)(Node **)) {
    pre(n);
    int i;

    Node **child;

    switch ((*n)->type) {
        case OBJECT:
            for (i = 0; i < (*n)->elems->size; i++) {
                child = &(((Bind *)vector_get((*n)->elems, i))->expr);
                node_walk(child, pre, post);
            }
        case STRICT:
            node_walk(&((*n)->expr), pre, post);
            break;
        case APPLY:
            node_walk(&((*n)->apply.optor), pre, post);
            node_walk(&((*n)->apply.opand), pre, post);
            break;
        case LET:
            for (i = 0; i < (*n)->let.binds->size; i++) {
                child = &(((Bind *)vector_get((*n)->let.binds, i))->expr);
                node_walk(child, pre, post);
            }
            node_walk(&((*n)->let.expr), pre, post);
            break;
        case LAMBDA:
            node_walk(&((*n)->lambda.expr), pre, post);
            break;
        case IF:
            node_walk(&((*n)->if_.pred), pre, post);
            node_walk(&((*n)->if_.cons), pre, post);
            node_walk(&((*n)->if_.alt), pre, post);
            break;
    }

    post(n);
}
