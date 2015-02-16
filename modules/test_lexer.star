import test lexer in let

enum num op lpar rpar space,

syntax = [
    rule num "\d+",
    rule op "[-+*/]",
    rule lpar "\\(",
    rule rpar "\\)",
    rule space "\\s+"
],

t = tokenize syntax in

test >> (map >> uncurry assert_equal) [
    [t "", []],
    [t "2", [{value="2", type=num}]],
    [t "-", [{value="-", type=op}]],
    [t "(", [{value="(", type=lpar}]],
    [t ")", [{value=")", type=rpar}]],
    [t " ", [{value=" ", type=space}]],
    [t "650", [{value="650", tye=num}]],
    [t " \t\n ", [{value=" \t\n ", type=space}]]
]
