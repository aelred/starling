let
s = import set,
set = s.set,
set_empty = s.set_empty,
set_add = s.set_add,
set_add_all = s.set_add_all,
set_items = s.set_items,
set_union = s.set_union,
set_diff = s.set_diff,

# declare a new non-terminal production
::= = \sym expr: [{sym=sym, expr=expr}],

# alternate between different productions
# this completely abuses left-associativity!
| = \production expr: {sym=(production.head).sym, expr=expr} : production,

grammar = \top terminals productions: 
    {top=top, terminals=terminals, productions=join productions},

parse = \grammar tokens: build_chart grammar tokens,

# build a new set by repeatedly mapping over a set until no new elements
limit = \more start: let
    limit_ = \old new: let
        new_ = fold set_union set_empty (map more (set_items new)) in
        if new_ = set_empty
        then old
        else limit_ (set_union new_ old) (set_diff new_ old) in
    limit_ start start,

# Kilbury Parsing, from http://www.cs.rit.edu/~swm/cs561/Ljunglof-2002a.pdf
build_chart = \grammar tokens: let

    edge = \node sym expr: {node=node, sym=sym, expr=expr},

    initial_chart = let
        initial_state = \pair: let
            j = pair._0, token = pair._1 in
            set [edge j token.type []] in
        set_empty : (map initial_state (zip nats tokens)),

    build_state = let
        more = \e:
            if e.expr = []
            then let
            predict =
                set (
                (map (\p: edge e.node p.sym (p.expr).tail)) (
                (filter (\p: p.expr != [] and ((p.expr).head = e.sym))
                grammar.productions))),
            combine = 
                set >>
                (map (\e2: edge e2.node e2.sym (e2.expr).tail)) >>
                (filter (\e2: e2.expr != [] and ((e2.expr).head = e.sym))) >>
                set_items (final_chart@(e.node)) in
            set_union predict combine
            else set_empty in
        limit more,

    final_chart = map build_state initial_chart in
    final_chart

in export ::= | grammar parse
