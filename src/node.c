#include <stdarg.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "node.h"
#include "parser.h"
#include "string.h"
#include "util.h"

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
        case CHAR:
            string_append(s, "%c", node->charval);
            break;
        case STRING:
        case IMPORT:
        case ACCESSOR:
            node_str_(node->accessor.expr, s);
            string_append(s, " %s", node->accessor.param);
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

static void node_code_(Node *node, string *s, int use_parens);

static void bind_code(vector *binds, string *s) {
    Bind *bind;
    int i;
    for (i=0; i < binds->size; i++) {
        bind = (Bind *)vector_get(binds, i);
        if (is_infix(bind->name))
            string_append(s, "(%s) = ", bind->name);
        else
            string_append(s, "%s = ", bind->name);
        node_code_(bind->expr, s, 0);
        if (i < binds->size-1) string_append(s, ", ");
    }
}

static void node_code_(Node *node, string *s, int use_parens) {
    int i;
    Node *inner;

    switch (node->type) {
        case APPLY:
        case EXPORT:
        case STRICT:
        case LET:
        case LAMBDA:
        case IF:
            if (use_parens) string_append(s, "(");
    }

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
            string_append(s, "'%c'", node->charval);
            break;
        case IMPORT:
            string_append(s, "import %s", node->strval);
            break;
        case ACCESSOR:
            node_code_(node->accessor.expr, s, 1);
            string_append(s, ".%s", node->accessor.param);
            break;
        case IDENT:
            if (is_infix(node->ident.name))
                string_append(s, "(%s)", node->ident.name);
            else
                string_append(s, node->ident.name);
            break;
        case APPLY:
            inner = node->apply.optor;
            if (inner->type == IDENT && is_infix(inner->ident.name)) {
                // This is an infix application
                node_code_(node->apply.opand, s,
                           node->apply.opand->type != APPLY);
                string_append(s, " %s", inner->ident.name);
            } else if (inner->type == ACCESSOR) {
                // This is an accessor application
                node_code_(node->apply.opand, s, 1);
                string_append(s, ".%s", inner->strval);
            } else {
                node_code_(inner, s, inner->type != APPLY);
                string_append(s, " ");
                node_code_(node->apply.opand, s, 1);
            }
            break;
        case OBJECT:
            string_append(s, "{");
            bind_code(node->elems, s);
            string_append(s, "}");
            break;
        case EXPORT:
            string_append(s, "export ");
            for (i=0; i < node->elems->size; i++) {
                string_append(s, "%s ", vector_get(node->elems, i));
            }
            break;
        case STRICT:
            string_append(s, "strict ");
            node_code_(node->expr, s, 1);
            break;
        case LET:
            string_append(s, "let ");
            bind_code(node->let.binds, s);
            string_append(s, " in ");
            node_code_(node->let.expr, s, 0);
            break;
        case LAMBDA:
            // Handle nested lambdas
            inner = node;
            while (inner->type == LAMBDA) {
                string_append(s, "%s ", inner->lambda.param);
                inner = inner->lambda.expr;
            }
            string_append(s, "-> ");
            node_code_(inner, s, 0);
            break;
        case IF:
            string_append(s, "if ");
            node_code_(node->if_.pred, s, 0);
            string_append(s, " then ");
            node_code_(node->if_.cons, s, 0);
            string_append(s, " else ");
            node_code_(node->if_.alt, s, 0);
            break;
        case BUILTIN_ADD:
            string_append(s, "__builtin_add");
            break;
        case BUILTIN_SUB:
            string_append(s, "__builtin_sub");
            break;
        case BUILTIN_MUL:
            string_append(s, "__builtin_mul");
            break;
        case BUILTIN_DIV:
            string_append(s, "__builtin_div");
            break;
        case BUILTIN_MOD:
            string_append(s, "__builtin_mod");
            break;
        case BUILTIN_POW:
            string_append(s, "__builtin_pow");
            break;
        case BUILTIN_EQ:
            string_append(s, "__builtin_eq");
            break;
        case BUILTIN_LE:
            string_append(s, "__builtin_le");
            break;
        case BUILTIN_CHR:
            string_append(s, "__builtin_chr");
            break;
        case BUILTIN_ORD:
            string_append(s, "__builtin_ord");
            break;
        case BUILTIN_REPR:
            string_append(s, "__builtin_repr");
            break;
        case BUILTIN_STR:
            string_append(s,"__builtin_str");
        default:
            string_append(s, "UNKNOWN");
    }

    switch (node->type) {
        case APPLY:
        case EXPORT:
        case STRICT:
        case LET:
        case LAMBDA:
        case IF:
            if (use_parens) string_append(s, ")");
    }
}

char *node_code(Node *node) {
    string *s = string_new();
    node_code_(node, s, 0);
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
