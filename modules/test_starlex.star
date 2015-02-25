let
t = import startoken,
ls = import starlex,
test = import test,
?= = test.assert_equal,
?!= = test.assert_unequal,

tok = type value -> {type=type, value=value} in

test.test [
    (ls.tokenize "") ?= [],

    (ls.tokenize "let map = f ->\n\tfold (x accum -> f x : accum) []") ?=
    [
        tok t.let_ "let", tok t.prefix_id "map", tok t.equals "=",
        tok t.prefix_id "f", tok t.arrow "->", tok t.prefix_id "fold", 
        tok t.lpar "(", tok t.prefix_id "x", tok t.prefix_id "accum", 
        tok t.arrow "->", tok t.prefix_id "f", tok t.prefix_id "x", 
        tok t.infix_id ":", tok t.prefix_id "accum", tok t.rpar ")", 
        tok t.llist "[", tok t.rlist "]"
    ],

    (ls.tokenize "let letter=1, lettuce=(10=letter) in [lettuce, letter]") ?=
    [
        tok t.let_ "let", tok t.prefix_id "letter", tok t.equals "=",
        tok t.number "1", tok t.comma ",", tok t.prefix_id "lettuce",
        tok t.equals "=", tok t.lpar "(", tok t.number "10",
        tok t.equals "=", tok t.prefix_id "letter", tok t.rpar ")",
        tok t.in_ "in", tok t.llist "[", tok t.prefix_id "lettuce",
        tok t.comma ",", tok t.prefix_id "letter", tok t.rlist "]"
    ],

    (ls.tokenize "let y={x=(a, b)}, enum a b in y.x._0") ?=
    [
        tok t.let_ "let", tok t.prefix_id "y", tok t.equals "=",
        tok t.lobj "{", tok t.prefix_id "x", tok t.equals "=",
        tok t.lpar "(", tok t.prefix_id "a", tok t.comma ",",
        tok t.prefix_id "b", tok t.rpar ")", tok t.robj "}",
        tok t.comma ",", tok t.enum_ "enum", tok t.prefix_id "a",
        tok t.prefix_id "b", tok t.in_ "in", tok t.prefix_id "y",
        tok t.dot ".", tok t.prefix_id "x", tok t.dot ".",
        tok t.prefix_id "_0"
    ],

    (ls.tokenize 
        "(\"hi\" has 'i')and((1 mod 2)=(1 pow 2) or (+-*/=<>?:@!&|))")
    ?= [
        tok t.lpar "(", tok t.string "\"hi\"", tok t.infix_id "has",
        tok t.char "'i'", tok t.rpar ")", tok t.infix_id "and", 
        tok t.lpar "(", tok t.lpar "(", tok t.number "1", 
        tok t.infix_id "mod", tok t.number "2", tok t.rpar ")", 
        tok t.equals "=", tok t.lpar "(", tok t.number "1", 
        tok t.infix_id "pow", tok t.number "2", tok t.rpar ")", 
        tok t.infix_id "or", tok t.lpar "(", 
        tok t.infix_id "+-*/=<>?:@!&|", tok t.rpar ")", tok t.rpar ")"
    ],

    (ls.tokenize "\"\\\"\\\\'\\b\\f\\n\\r\\t\\v\\x45\\x0e\\123\\20\\7\"") ?=
    [tok t.string "\"\\\"\\\\'\\b\\f\\n\\r\\t\\v\\x45\\x0e\\123\\20\\7\""],

    (ls.tokenize >> join [
        "['a', ' ', '\\'', '\"', '\\\"', '\\\\', '\\b', '\\f', '\\n',", 
        "'\\r', '\\t', '\\v', '\\x45', '\\x0e', '\\123', '\\20', '\\7']"]) 
    ?= [
        tok t.llist "[", tok t.char "'a'", tok t.comma ",", 
        tok t.char "' '", tok t.comma ",", tok t.char "'\\''", 
        tok t.comma ",", tok t.char "'\"'", tok t.comma ",", 
        tok t.char "'\\\"'", tok t.comma ",", tok t.char "'\\\\'", 
        tok t.comma ",", tok t.char "'\\b'", tok t.comma ",", 
        tok t.char "'\\f'", tok t.comma ",", tok t.char "'\\n'", 
        tok t.comma ",", tok t.char "'\\r'", tok t.comma ",", 
        tok t.char "'\\t'", tok t.comma ",", tok t.char "'\\v'", 
        tok t.comma ",", tok t.char "'\\x45'", tok t.comma ",", 
        tok t.char "'\\x0e'", tok t.comma ",", tok t.char "'\\123'", 
        tok t.comma ",", tok t.char "'\\20'", tok t.comma ",", 
        tok t.char "'\\7'", tok t.rlist "]"
    ],

    (ls.tokenize "if True or False # baz  \n then import foo else export bar")
    ?= [
        tok t.if_ "if", tok t.bool "True", tok t.infix_id "or",
        tok t.bool "False", tok t.then_ "then", tok t.import_ "import",
        tok t.prefix_id "foo", tok t.else_ "else", tok t.export_ "export",
        tok t.prefix_id "bar"
    ]
]
