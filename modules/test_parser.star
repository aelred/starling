let
test = import test,
lexer = import lexer,
parser = import parser,

?= = test.assert_equal,
?!= = test.assert_unequal,

::= = parser.::=,
| = parser.|,
tree = parser.tree,
leaf = parser.leaf,

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

p = 
    map (parser.suppress [expr, par_expr, lpar, rpar]) >>
    (parser.parse grammar) >> 
    (lexer.tokenize syntax) in 

test.test [
    (p "2") ?= [leaf num "2"],
    (p "var") ?= [leaf ident "var"],

    (p "num+10") ?= [
        tree op_expr [
            leaf ident "num",
            leaf op "+",
            leaf num "10"
        ]
    ],

    # test that all ambiguous parses are found
    (p "2*(1-3/10)") ?= [
        tree op_expr [
            leaf num "2",
            leaf op "*",
            tree op_expr [
                leaf num "1",
                leaf op "-",
                tree op_expr [
                    leaf num "3",
                    leaf op "/",
                    leaf num "10"
                ]
            ]
        ],
        tree op_expr [
            leaf num "2",
            leaf op "*",
            tree op_expr [
                tree op_expr [
                    leaf num "1",
                    leaf op "-",
                    leaf num "3"
                ],
                leaf op "/",
                leaf num "10"
            ]
        ]
    ]
]
