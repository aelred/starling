#ifndef NODE_H__
#define NODE_H__

#include <stddef.h>
#include "vector.h"

struct Node;

typedef struct {
    int is_enum;
    char *name;
    struct Node *expr;
} Bind;

typedef struct Node {
    int type;
    union {
        // BOOL INT
        int intval;
        // PREFIX INFIX STRING CHAR IMPORT ACCESSOR
        char *strval;
        // OBJECT EXPORT
        vector *elems;
        // STRICT
        struct Node *expr;
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
            char *param;
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

void node_str(Node *node, char *s, size_t n);

Node *node(int type);

#endif
