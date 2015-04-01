let
regex = import regex,

fa_to_dot = fa -> let
    start = join ["start -> ", str (fa.start)],
    finals = map (final -> (str final) ++ " [shape=doublecircle]") fa.final,

    range_str = r ->
        if r._0 == r._1
        then str r._0
        else join [repr r._0, "-", repr r._1],

    sym_str = sym -> 
        if (str sym.type) == "lit"
        then range_str sym.range
        else if (str sym.type) == "eps"
        then "eps"
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

    transitions = map trans_str fa.trans,

    body = let
        indent = s -> join ["\t", s, ";\n"] in
        map indent (join [finals, [start], transitions]) in

    join ["digraph g {\n", join body, "}"],

main = fa_to_dot >> regex.build_dfa in

export main fa_to_dot
