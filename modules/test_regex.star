let
match = import regex.match,
test = import test,

# match function, giving input and which part of input should match
m = \inp part: {inp=inp, res={str=part, match=True}},

# total match function where regex should completely match input
tm = \inp: m inp inp,

re = \pat pos neg: let
    assertions = \pred msg: 
        map (\s: test.assert (pred s) (join [pat, msg, str s])),
    pos_t = assertions (\s: (match pat s.inp) = s.res) " doesn't match " pos,
    neg_t = assertions (\s: not (match pat s).match) " matches " neg in
    cat pos_t neg_t in

test.test >> join [
    re "" [m "anything" "", m "at" "", m "all" ""] [],
    re "." [tm "c", m "hi" "h", m "what" "w"] [""],
    re "this" [tm "this"] ["", "not this"],
    re "[a]" [tm "a", m "ad" "a"] ["", "b", "bad"],
    re "[ab]" [tm "a", tm "b", m "add" "a"] ["", "yab"],
    re "[a-c]" [tm "a", tm "b", tm "c"] ["", "d", "da"],
    re "a.c" [tm "abc", tm "adc", tm "a.c"] ["A.C", "xyz"],
    re "[a.c]" [tm "a", tm ".", tm "c"] ["", "d"],
    re "[abcx-z]" [tm "a", tm "b", tm "c", tm "x", tm "y", tm "z"] ["d", "Z"],
    re "[a-cx-z]" [tm "a", tm "b", tm "c", tm "x", tm "y", tm "z"] ["d", "Z"],
    re "[abc-]" [tm "a", tm "b", tm "c", tm "-"] ["d", "A"],
    re "[-abc]" [tm "a", tm "b", tm "c", tm "-"] ["d", "A"],
    re "[]abc]" [tm "]", tm "a", tm "b", tm "c"] ["[", "A", ""],
    re "[][]" [tm "]", tm "["] ["(", "", "a"],
    re "[^abc]" [tm "d", m "ha" "h", m "eb" "e", m "ic" "i"] ["a", "cut"],
    re "[^-]" [tm "a", tm "b", tm "c", m "a-c" "a"] ["-"],
    re "[^]]" [tm "a", tm "o", tm "e"] ["", "]"],
    re "^hi" [tm "hi", m "high" "hi"] ["^hi", "ahi", "what", ""],
    re "hi^" [] ["hi", "", "ahi", "hi^"],
    re "hi$" [tm "hi"] ["", "high", "h", "hi$"],
    re "h$i" [] ["", "hi", "high", "h", "h$i"],
    re "^$" [tm ""] ["^$", "a", "^", "$"],
    re "^^a$$" [tm "a"] ["", "aa", "b", "^^a$$"],
    re "ba(na)*" [tm "ba", tm "bana", tm "banana"] ["", "na", "nabana"],
    re "((a|d)c)*$" [tm "", tm "ac", tm "dc", tm "acdc"] ["adc", "c", "a"],
    re "a?$" [tm "a", tm ""] ["e", "aa", "a?"],
    re "a+$" [tm "a", tm "aa", tm "aaa"] ["", "ab", "ba", "a+"],
    re "e{3}$" [tm "eee"] ["", "e", "ee", "eeee", "aaa"],
    re "e{3,}$" [tm "eee", tm "eeee"] ["", "e", "ee", "aaa", "eeea"],
    re "a{3,5}$" [tm "aaa", tm "aaaa", tm "aaaaa"] ["aa", "aaaaaa", "bbb"],
    # '\\\\' because we must first escape starling, then regex to get a '\'
    re 
        "\\\\\\{\\}\\[\\]\\(\\)\\^\\$\\.\\|\\*\\+\\?"
        [tm "\\{}[]()^$.|*+?"] ["", "\\\\"],
    re "[\\(.]" [tm "\\", tm "(", tm "."] ["", "a"],
    re "[[:upper:]][[:lower:]]*$" [tm "Hello", tm "A"] ["", "world", "b"],
    re "[1[:alpha:]]" [tm "1", tm "B", tm "C", tm "d"] ["", "0"],
    re "[[:digit:]]" [tm "0", tm "1", tm "8", tm "9"] ["a", ""],
    re "[[:xdigit:]]" [tm "0", tm "5", tm "A", tm "f"] ["G", "g", ""],
    re "[[:alnum:]]+$" [tm "9MyVar", tm "myVar1"] ["my_var", "%", ""],
    re "[[:word:]]+$" [tm "my_var", tm "9MyVar", tm "my_Var1"] ["%", ""],
    re "[[:punct:]]*$" [tm "+,@\\\'"] [" ", "0", "h", "U"],
    re "[[:space:]]+$" [tm " \t\r\n\v\f"] ["", "abc"],
    re "[[:cntrl:]]*$" [tm "\x00\n\x1F\x7F"] [" ", "7"],
    re "[[:graph:]]+$" [tm "a!~0U"] ["", " ", "\n", "\x7F"],
    re "[[:print:]]+$" [tm "a!~0U "] ["", "\n", "\x7F"],
    re "[:digit:]" [tm ":", tm "d", tm "i"] ["0", "3"],
    re "\\u\\l\\a\\d\\D\\x\\w\\W\\s\\S\\p$" [tm "Abc0%f_\n\t\x7E\""] [""]
]
