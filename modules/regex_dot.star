let
regex = import regex,

main = pattern -> let
    dfa = regex.minify_dfa >> regex.to_dfa >> regex.nfa pattern,
    start = join ["start -> ", str (dfa.start)],
    finals = map (final -> cat (str final) " [shape=doublecircle]") dfa.final,

    range_str = r ->
        if r._0 == r._1
        then str r._0
        else join [repr r._0, "-", repr r._1],

    sym_str = sym -> 
        if (str sym.type) == "lit"
        then range_str sym.range
        else if (str sym.type) == "ass_start"
        then "^"
        else "$",

    trans_str = t -> 
        join [
            str t.start, 
            " -> ", 
            str t.end, 
            " [label=\"", 
            sym_str t.sym, 
            "\"]"
        ],

    transitions = map trans_str dfa.trans,

    body = let
        indent = s -> join ["\t", s, ";\n"] in
        map indent (join [finals, [start], transitions]) in

    join ["digraph g {\n", join body, "}"] in

export main
