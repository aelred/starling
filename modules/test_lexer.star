let
test = import test,
lexer = import lexer,

?= = test.assert_equal,
rule = lexer.rule,

enum num op lpar rpar space ident print,

syntax = [
    rule num "\d+",
    rule op "[-+*/]",
    rule lpar "\\(",
    rule rpar "\\)",
    rule space "\\s+",
    rule print "print",
    rule ident "\\a+"
],

t = lexer.tokenize syntax in

test.test [
    (t "") ?= [],
    (t "2") ?= [{value="2", type=num}],
    (t "-") ?= [{value="-", type=op}],
    (t "(") ?= [{value="(", type=lpar}],
    (t ")") ?= [{value=")", type=rpar}],
    (t " ") ?= [{value=" ", type=space}],
    (t "var") ?= [{value="var", type=ident}],
    (t "print") ?= [{value="print", type=print}],
    (t "650") ?= [{value="650", type=num}],
    (t " \t\n ") ?= [{value=" \t\n ", type=space}],
    (t "num+10") ?=
    [{value="num", type=ident}, {value="+", type=op}, {value="10", type=num}],
    (t " 1\n*(3 - 10) /z") ?=
    [{value=" ", type=space}, {value="1", type=num}, 
     {value="\n", type=space}, {value="*", type=op}, 
     {value="(", type=lpar}, {value="3", type=num},
     {value=" ", type=space}, {value="-", type=op}, 
     {value=" ", type=space}, {value="10", type=num},
     {value=")", type=rpar}, {value=" ", type=space},
     {value="/", type=op}, {value="z", type=ident}],
    (lexer.ignore [space] >> t " 1\n*(3 - 10) /z") ?=
    [{value="1", type=num}, {value="*", type=op}, 
     {value="(", type=lpar}, {value="3", type=num},
     {value="-", type=op}, {value="10", type=num},
     {value=")", type=rpar}, {value="/", type=op}, 
     {value="z", type=ident}],
    (lexer.ignore [space] >> t "prim print printer") ?=
    [{value="prim", type=ident}, {value="print", type=print},
     {value="printer", type=ident}]
]
