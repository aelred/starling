let
test = import test,
lexer = import lexer,
parser = import parser,

?= = test.assert_equal,
?!= = test.assert_unequal,

::= = parser.::=,
| = parser.|,

rule = lexer.rule,

enum num op lpar rpar ident expr op_expr par_expr,

syntax = [
    rule num "\d+",
    rule op "[-+*/]",
    rule lpar "\\(",
    rule rpar "\\)",
    rule ident "\\a+"
],

# left- and right- recursive grammar
grammar = parser.grammar expr [num, op, lpar, rpar, ident] [
    expr ::= [num] | [ident] | [op_expr] | [par_expr],
    par_expr ::= [lpar, expr, rpar],
    op_expr ::= [expr, op, expr]
],

tree = \sym children: {sym=sym, children=children},

p = parser.parse grammar >> (lexer.tokenize syntax) in 

test.test [
    (p "2") ?= (tree expr [tree num "2"]),
    (p "var") ?= (tree expr [tree ident "var"]),

    (p "num+10") ?= (
        tree expr [tree op_expr [
            tree expr [tree ident "num"],
            tree op "+",
            tree expr [tree num "10"]
        ]]
    ),

    (p "2*(1-3-10)/z") ?= (
        tree expr [tree op_expr [
            tree expr [tree num "2"],
            tree op "*",
            tree expr [tree op_expr [
                tree expr [tree op_expr [
                    tree expr [tree op_expr [
                        tree expr [tree num "1"],
                        tree op "-",
                        tree expr [tree num "3"]
                    ]],
                    tree op "-",
                    tree expr [tree num "10"]
                ]],
                tree op "/",
                tree expr [tree ident "z"]
            ]]
        ]]
    )
]
