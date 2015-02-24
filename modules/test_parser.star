let
test = import test,
lexer = import lexer,
parser = import parser,

?= = test.assert_equal,
?!= = test.assert_unequal,

::= = parser.::=,
| = parser.|,

enum num op lpar rpar ident expr op_expr par_expr,

syntax = [
    rule num "\d+",
    rule op "[-+*/]",
    rule lpar "\\(",
    rule rpar "\\)",
    rule ident "\\a+"
],

# left- and right- recursive grammar
grammar = parser.grammar expr [
    expr ::= [num] | [ident] | [op_expr] | [par_expr],
    par_expr ::= [lpar, expr, rpar],
    op_expr ::= [expr, op, expr]
],

tree = \type children: {type=type, children=children},

p = parser.parse grammar >> (lexer.lex syntax) in 

test.test [
    (p "2") ?= (tree expr [tree (term num) "2"]),
    (p "var") ?= (tree expr [tree (term ident) "var"]),

    (p "num+10") ?= (
        tree expr [tree op_expr [
            tree expr [tree ident "num"],
            tree (term op) "+",
            tree expr [tree num "10"]
        ]]
    ),

    (p "2*(1-3-10)/z") ?= (
        tree expr [tree op_expr [
            tree expr [tree (term num) "2"],
            tree (term op) "*",
            tree expr [tree op_expr [
                tree expr [tree op_expr [
                    tree expr [tree op_expr [
                        tree expr [tree (term num) "1"],
                        tree (term op) "-",
                        tree expr [tree (term num) "3"]
                    ]],
                    tree (term op) "-",
                    tree expr [tree (term num) "10"]
                ]],
                tree (term op) "/",
                tree expr [tree (term ident) "z"]
            ]]
        ]]
    )
]
