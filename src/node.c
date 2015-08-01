#include <stdarg.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "node.h"
#include "parser.h"

typedef struct {
    char *s;
    size_t len;
    size_t capacity;
} string;

Node *node(int type) {
    Node *n = malloc(sizeof(Node));
    n->type = type;
    return n;
}

void print(string *s, const char *format, ...) {
    va_list args;
    int written;
    int rewrite;

    do {
        va_start(args, format);
        written = vsnprintf(s->s+s->len, s->capacity - s->len, format, args);
        va_end(args);

        if (s->len + written >= s->capacity) {
            // Resize buffer
            s->capacity *= 2;
            s->s = realloc(s->s, sizeof(char) * s->capacity);
            // Rewrite string
            rewrite = 1;
        } else {
            rewrite = 0;
        }
    } while (rewrite);

    s->len += written;
}

static void node_str_(Node *node, string *s);

void bind_str(vector *binds, string *s) {
    Bind *bind;
    int i;
    for (i=0; i < binds->size; i++) {
        bind = (Bind *)vector_get(binds, i);
        if (bind->is_enum) {
            print(s, "%s ", bind->name);
        } else {
            print(s, "[%s ", bind->name);
            node_str_(bind->expr, s);
            print(s, "] ");
        }
    }
}

static void node_str_(Node *node, string *s) {
    const char *name = token_name(node->type);
    int i;

    print(s, "[%s ", name);

    switch (node->type) {
        case BOOL:
        case INT:
            print(s, "%d", node->intval);
            break;
        case IDENT:
        case STRING:
        case CHAR:
        case IMPORT:
        case ACCESSOR:
            print(s, node->strval);
            break;
        case APPLY:
            node_str_(node->apply.optor, s);
            print(s, " ");
            node_str_(node->apply.opand, s);
            break;
        case OBJECT:
            bind_str(node->elems, s);
            break;
        case EXPORT:
            for (i=0; i < node->elems->size; i++) {
                print(s, "%s ", vector_get(node->elems, i));
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
            print(s, "%s ", node->lambda.param);
            node_str_(node->lambda.expr, s);
            break;
        case IF:
            node_str_(node->if_.pred, s);
            print(s, " ");
            node_str_(node->if_.cons, s);
            print(s, " ");
            node_str_(node->if_.alt, s);
            break;
        default:
            print(s, "UNKNOWN");
    }

    print(s, "]");
}

const int INITIAL_SIZE = 128;

char *node_str(Node *node) {
    string s;
    s.s = malloc(sizeof(char) * INITIAL_SIZE);
    s.len = 0;
    s.capacity = INITIAL_SIZE;
    node_str_(node, &s);
    return s.s;
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
