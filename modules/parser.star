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

grammar = \top productions: {top=top, productions=join productions},

parse = \prod tokens: build_chart prod tokens,

# build a new set by repeatedly mapping over a set until no new elements
limit = \more start: let
    limit_ = \old new: let
        new_ = fold1 set_union (map more new) in
        if new_ = set_empty
        then old
        else limit_ (set_union new_ old) (set_diff new_ old) in
    limit_ start start

# TODO
# Kilbury Parsing, from http://www.cs.rit.edu/~swm/cs561/Ljunglof-2002a.pdf
# build_chart = \prod tokens: let
# 
#     initial_chart = let
#         initial_state = \j token: set [(j, term token)] in
#         set_empty : (map initial_state (zip nats tokens))
# 
#     build_state = \k: let
#         more = \edge:
#             if (edge._1).type = concat
#             then let
#             predict = [{k, (edge._1).a}],
#             combine = in
#             set_union predict combine
#             else set_empty in
#         limit more,
# 
#     final_chart = map build_state (zip nats initial_chart) in
#     final_chart

in export ::= | grammar parse
