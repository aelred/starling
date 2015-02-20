let
test = import test,
lexer = import lexer,

assert_equal = test.assert_equal,
rule = lexer.rule,

enum num op lpar rpar space,

syntax = [
    rule num "\d+",
    rule op "[-+*/]",
    rule lpar "\\(",
    rule rpar "\\)",
    rule space "\\s+"
],

t = lexer.tokenize syntax in

test.test >> (map >> uncurry assert_equal) [
    [t "", []],
    [t "2", [{value="2", type=num}]],
    [t "-", [{value="-", type=op}]],
    [t "(", [{value="(", type=lpar}]],
    [t ")", [{value=")", type=rpar}]],
    [t " ", [{value=" ", type=space}]],
    [t "650", [{value="650", type=num}]],
    [t " \t\n ", [{value=" \t\n ", type=space}]],
    [
        t "2+10", 
        [{value="2", type=num}, {value="+", type=op}, {value="10", type=num}]
    ],
    [
        t " 1\n*(3 - 10) /4",
        [{value=" ", type=space}, {value="1", type=num}, 
         {value="\n", type=space}, {value="*", type=op}, 
         {value="(", type=lpar}, {value="3", type=num},
         {value=" ", type=space}, {value="-", type=op}, 
         {value=" ", type=space}, {value="10", type=num},
         {value=")", type=rpar}, {value=" ", type=space},
         {value="/", type=op}, {value="4", type=num}]
    ],
    [
        lexer.ignore space >> t " 1\n*(3 - 10) /4",
        [{value="1", type=num}, {value="*", type=op}, 
         {value="(", type=lpar}, {value="3", type=num},
         {value="-", type=op}, {value="10", type=num},
         {value=")", type=rpar}, {value="/", type=op}, 
         {value="4", type=num}]
    ]
]
