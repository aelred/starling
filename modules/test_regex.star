import regex in let 

test = \p xs ys: let
    false_neg = filter (not . (match p)) xs,
    false_pos = filter (match p) ys in
    cat false_neg false_pos,

test_all = let 
    fold_test = \t accum: let 
        failures = test (t@0) (t@1) (t@2),
        pass = failures = [] in
        if pass then accum else [t@0, failures] : accum in
    fold fold_test [] in

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
    ["a{3,5}$", ["aaa", "aaaa", "aaaaa"], ["aa", "aaaaaa", "a", "bbb"]]
]
