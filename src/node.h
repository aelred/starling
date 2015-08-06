#ifndef NODE_H__
#define NODE_H__

#include <stddef.h>
#include "vector.h"

struct Node;

typedef struct {
    char *name;
    struct Node *expr;
    vector *uses;
} Bind;

typedef struct Node {
    int type;
    union {
        // BOOL INT
        int intval;
        // STRING CHAR IMPORT ACCESSOR
        const char *strval;
        // OBJECT EXPORT
        vector *elems;
        // STRICT
        struct Node *expr;
        // IDENT
        struct {
            const char *name;
            Bind *def;
        } ident;
        // APPLY
        struct {
            struct Node *optor;
            struct Node *opand;
        } apply;
        // LET
        struct {
            vector *binds;
            struct Node *expr;
        } let;
        // LAMBDA
        struct {
            const char *param;
            struct Node *expr;
        } lambda;
        // IF
        struct {
            struct Node *pred;
            struct Node *cons;
            struct Node *alt;
        } if_;
    };
} Node;

char *node_str(Node *node);

char *node_code(Node *node);

void node_walk(Node **node, void (pre)(Node **), void (post)(Node **));

Node *node(int type);

#endif
