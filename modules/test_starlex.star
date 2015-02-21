let
ls = import starlex,
test = import test,
?= = test.assert_equal,
?!= = test.assert_unequal,

tok = \type value: {type=type, value=value} in

test.test [
    (ls.tokenize "") ?= [],

    (ls.tokenize "let map = \\f:\n\tfold (\\x accum: f x : accum) []") ?=
    [
        tok ls.let_ "let", tok ls.prefix_id "map", tok ls.equals "=",
        tok ls.lambda "\\", tok ls.prefix_id "f", tok ls.colon ":",
        tok ls.prefix_id "fold", tok ls.lpar "(", tok ls.lambda "\\",
        tok ls.prefix_id "x", tok ls.prefix_id "accum", tok ls.colon ":",
        tok ls.prefix_id "f", tok ls.prefix_id "x", tok ls.colon ":",
        tok ls.prefix_id "accum", tok ls.rpar ")", tok ls.llist "[",
        tok ls.rlist "]"
    ],

    (ls.tokenize "let letter=1, lettuce=(10=letter) in [lettuce, letter]") ?=
    [
        tok ls.let_ "let", tok ls.prefix_id "letter", tok ls.equals "=",
        tok ls.number "1", tok ls.comma ",", tok ls.prefix_id "lettuce",
        tok ls.equals "=", tok ls.lpar "(", tok ls.number "10",
        tok ls.equals "=", tok ls.prefix_id "letter", tok ls.rpar ")",
        tok ls.in_ "in", tok ls.llist "[", tok ls.prefix_id "lettuce",
        tok ls.comma ",", tok ls.prefix_id "letter", tok ls.rlist "]"
    ],

    (ls.tokenize "let y={x=(a, b)}, enum a b in y.x._0") ?=
    [
        tok ls.let_ "let", tok ls.prefix_id "y", tok ls.equals "=",
        tok ls.lobj "{", tok ls.prefix_id "x", tok ls.equals "=",
        tok ls.lpar "(", tok ls.prefix_id "a", tok ls.comma ",",
        tok ls.prefix_id "b", tok ls.rpar ")", tok ls.robj "}",
        tok ls.comma ",", tok ls.enum_ "enum", tok ls.prefix_id "a",
        tok ls.prefix_id "b", tok ls.in_ "in", tok ls.prefix_id "y",
        tok ls.dot ".", tok ls.prefix_id "x", tok ls.dot ".",
        tok ls.prefix_id "_0"
    ],

    (ls.tokenize "(\"hi\" has 'i')and((1 mod 2)=(1 pow 2) or (+-*/=<>?:@!))")
    ?= [
        tok ls.lpar "(", tok ls.string "\"hi\"", tok ls.infix_id "has",
        tok ls.char "'i'", tok ls.rpar ")", tok ls.infix_id "and", 
        tok ls.lpar "(", tok ls.lpar "(", tok ls.number "1", 
        tok ls.infix_id "mod", tok ls.number "2", tok ls.rpar ")", 
        tok ls.equals "=", tok ls.lpar "(", tok ls.number "1", 
        tok ls.infix_id "pow", tok ls.number "2", tok ls.rpar ")", 
        tok ls.infix_id "or", tok ls.lpar "(", tok ls.infix_id "+-*/=<>?:@!", 
        tok ls.rpar ")", tok ls.rpar ")"
    ],

    (ls.tokenize "\"\\\"\\\\'\\b\\f\\n\\r\\t\\v\\x45\\x0e\\123\\20\\7\"") ?=
    [tok ls.string "\"\\\"\\\\'\\b\\f\\n\\r\\t\\v\\x45\\x0e\\123\\20\\7\""],

    (ls.tokenize >> join [
        "['a', ' ', '\\'', '\"', '\\\"', '\\\\', '\\b', '\\f', '\\n',", 
        "'\\r', '\\t', '\\v', '\\x45', '\\x0e', '\\123', '\\20', '\\7']"]) 
    ?= [
        tok ls.llist "[", tok ls.char "'a'", tok ls.comma ",", 
        tok ls.char "' '", tok ls.comma ",", tok ls.char "'\\''", 
        tok ls.comma ",", tok ls.char "'\"'", tok ls.comma ",", 
        tok ls.char "'\\\"'", tok ls.comma ",", tok ls.char "'\\\\'", 
        tok ls.comma ",", tok ls.char "'\\b'", tok ls.comma ",", 
        tok ls.char "'\\f'", tok ls.comma ",", tok ls.char "'\\n'", 
        tok ls.comma ",", tok ls.char "'\\r'", tok ls.comma ",", 
        tok ls.char "'\\t'", tok ls.comma ",", tok ls.char "'\\v'", 
        tok ls.comma ",", tok ls.char "'\\x45'", tok ls.comma ",", 
        tok ls.char "'\\x0e'", tok ls.comma ",", tok ls.char "'\\123'", 
        tok ls.comma ",", tok ls.char "'\\20'", tok ls.comma ",", 
        tok ls.char "'\\7'", tok ls.rlist "]"
    ],

    (ls.tokenize "if True or False # baz  \n then import foo else export bar")
    ?= [
        tok ls.if_ "if", tok ls.bool "True", tok ls.infix_id "or",
        tok ls.bool "False", tok ls.then_ "then", tok ls.import_ "import",
        tok ls.prefix_id "foo", tok ls.else_ "else", tok ls.export_ "export",
        tok ls.prefix_id "bar"
    ]
]
