#ifndef NODE_H__
#define NODE_H__

#include <stddef.h>
#include "vector.h"

struct Node;

// A binding from a name to an expression
typedef struct {
    char *name;
    struct Node *expr;
    vector *uses;
} Bind;

// A node in the abstract syntax tree
typedef struct Node {
    int type;
    vector *dependencies;
    union {
        // BOOL INT
        int intval;
        // CHAR
        char charval;
        // STRING IMPORT ACCESSOR
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

// Return string representation of given node
char *node_str(Node *node);

// Return starling code representation of given node
char *node_code(Node *node);

// Walk over syntax tree, applying pre- and post- functions
void node_walk(Node **node, void (pre)(Node **), void (post)(Node **));

// Create a node of a given type
Node *node(int type);

#endif
