let
test = import test,
?= = test.assert_equal,
?!= = test.assert_unequal,

regex_dot = import regex_dot,
dot = regex_dot.main,

digraph = strs start finals -> let
    final_strs = map (final -> cat final " [shape=doublecircle]") finals,
    new_strs = cat final_strs (join ["start -> ", start] : strs) in
    join [
        "digraph g {\n",
        join (map (s -> join ["\t", s, ";\n"]) new_strs), 
        "}"
    ]
in

test.test [
    dot "" ?= (digraph [] "0" ["0"]),
    dot "a" ?= (digraph ["1 -> 0 [label=\"a\"]"] "1" ["0"]),
    dot "[a-c]" ?= (digraph ["1 -> 0 [label=\"'a'-'c'\"]"] "1" ["0"]),

    dot "abc" ?= (
    digraph [
        "1 -> 0 [label=\"c\"]", "2 -> 1 [label=\"b\"]", 
        "3 -> 2 [label=\"a\"]"
    ] "3" ["0"]),

    dot "abc|abd" ?= (
    digraph [
        "2 -> 0 [label=\"c\"]", "2 -> 1 [label=\"d\"]", 
        "3 -> 2 [label=\"b\"]", "4 -> 3 [label=\"a\"]"
    ] "4" ["0", "1"])
]
