import regex test in let 

re_test = \pat pos neg: let
    pos_t = map (\x: [match pat x, join [pat, " doesn't match ", x]]) pos,
    neg_t = map (\x: [not (match pat x), join [pat, " matches ", x]]) neg in
    cat pos_t neg_t,

test_all = test . join . (map (\t: re_test (t@0) (t@1) (t@2))) in

test_all [
    ["", ["anything", "at", "all"], []],
    [".", ["c", "hi", "what"], [""]],
    ["this", ["this"], ["", "not this"]],
    ["[a]", ["a", "ad"], ["", "b", "bad"]],
    ["[ab]", ["a", "b", "add"], ["", "yab"]],
    ["[a-c]", ["a", "b", "c"], ["", "d", "da"]],
    ["a.c", ["abc", "adc", "a.c"], ["A.C", "xyz"]],
    ["[a.c]", ["a", ".", "c"], ["", "d"]],
    ["[abcx-z]", ["a", "b", "c", "x", "y", "z"], ["d", "Z"]],
    ["[a-cx-z]", ["a", "b", "c", "x", "y", "z"], ["d", "Z"]],
    ["[abc-]", ["a", "b", "c", "-"], ["d", "A"]],
    ["[-abc]", ["a", "b", "c", "-"], ["d", "A"]],
    ["[]abc]", ["]", "a", "b", "c"], ["[", "A", ""]],
    ["[][]", ["]", "["], ["(", "", "a"]],
    ["[^abc]", ["d", "ha", "eb", "ic"], ["a", "b", "c", "cut"]],
    ["[^-]", ["a", "b", "c", "a-c"], ["-"]],
    ["[^]]", ["a", "o", "e"], ["", "]"]],
    ["^hi", ["hi", "high"], ["^hi", "ahi", "what", ""]],
    ["hi^", [], ["hi", "", "ahi", "hi^"]],
    ["hi$", ["hi"], ["", "high", "h", "hi$"]],
    ["h$i", [], ["", "hi", "high", "h", "h$i"]],
    ["^$", [""], ["^$", "a", "^", "$"]],
    ["^^a$$", ["a"], ["", "aa", "b", "^^a$$"]],
    ["ba(na)*$", ["ba", "bana", "banana"], ["", "na", "ban", "banabana"]],
    ["((a|d)c)*$", ["", "ac", "dc", "acdc"], ["adc", "c", "aac", "a"]],
    ["a?$", ["a", ""], ["e", "aa", "a?"]],
    ["a+$", ["a", "aa", "aaa"], ["", "ab", "ba", "a+"]],
    ["e{3}$", ["eee"], ["", "e", "ee", "eeee", "aaa"]],
    ["e{3,}$", ["eee", "eeee"], ["", "e", "ee", "aaa", "eeea"]],
    ["a{3,5}$", ["aaa", "aaaa", "aaaaa"], ["aa", "aaaaaa", "a", "bbb"]],
    ["\\\{\}\[\]\(\)\^\$\.\|\*\+\?", ["\{}[]()^$.|*+?"], ["", "\\"]],
    # the double backslash isn't important here! for syntax colouring
    ["[\(.]", ["\\", "(", "."], ["", "a"]],
    ["[[:digit:]]", ["0", "1", "8", "9"], ["a", ""]],
    ["[[:upper:]][[:lower:]]*", ["Hello", "A"], ["", "world", "b"]],
    ["[1[:alpha:]]", ["1", "B", "C", "d"], ["", "0"]],
    ["[[:xdigit:]]", ["0", "5", "A", "f"], ["G", "g", ""]],
    ["[[:alnum:]_]+", ["my_var", "9MyVar", "my_Var1"], ["%", ""]],
    ["[[:punct:]]", ["+", ",", "@"], ["0", "h", "U"]],
    ["[:digit:]", [":", "d", "i"], ["0", "3"]]
]
