let
s = import set,
set = s.set,
set_empty = s.set_empty,
set_has = s.set_has,
set_add = s.set_add,
set_add_all = s.set_add_all,
set_items = s.set_items,
set_union = s.set_union,
set_diff = s.set_diff,

dict = import dict,

# tail recursive methods
# these don't improve the time/space complexity, but they help with Python's
# recursion limit
tmap = f -> reverse >> (foldl (ys x -> f x : ys) []),
tfilter = f -> reverse >> (foldl (ys x -> if f x then x : ys else ys) []),
tjoin = foldl cat [],

# declare a new non-terminal production
::= = sym expr -> [{sym=sym, expr=expr}],

# alternate between different productions
# this completely abuses left-associativity!
| = production expr -> {sym=(production.head).sym, expr=expr} : production,

# create a new grammar
# start: the top-level symbol to start the pars
# terminals: a list of terminal symbols with no productions
# productions: a list of productions, made with the ::= operator
grammar = start terminals productions -> let
    joined_prod = join productions in
    {
        start=start, terminals=set terminals, 
        left_corner_map=multidict (tmap (p -> ((p.expr).head, p)) joined_prod), 
        productions=multidict (tmap (p -> (p.sym, p)) joined_prod)
    },

# dictionary with a list for every value
multidict = let
    add_elem = d pair -> let
        key = pair._0, value = pair._1,
        old_value = if dict.has_key key d then dict.get key d else [] in
        dict.put key (value : old_value) d in
    foldl add_elem (dict.dict []),

# get all parse trees for a given list of tokens
parse = grammar tokens -> let
    length_tokens = length tokens,
    token_dict = dict.dict (zip nats tokens),
    edge_trees = build_trees grammar token_dict passive_chart,
    passive_chart = passive_edges final_chart,
    final_chart = build_chart grammar tokens,
    results = 
        tfilter (e -> (e._0).j == length_tokens) >> 
        (dict.get (0, grammar.start)) edge_trees in
    (results.head)._1,

# remove the given symbols from the parse tree
# when used to remove top-level symbol, it will only return the first
# child of the top level symbol.
suppress = syms parse_tree -> let
    sym_set = set syms,
    suppress_ = parse_tree -> let
        suppress_children = tjoin (tmap suppress_ parse_tree.children) in
        if set_has parse_tree.sym sym_set
        # remove this node and return its children
        then if parse_tree.is_leaf then [] else suppress_children
        # keep this node
        else if parse_tree.is_leaf 
        then [parse_tree]
        else [tree parse_tree.sym suppress_children] in
    (suppress_ parse_tree).head,
    
# build a new set by repeatedly mapping over a set until no new elements
limit = more start -> let
    limit_ = old new -> let
        new_ = fold (set_union >> more) set_empty (set_items new) in
        if new_ == set_empty
        then old
        else limit_ (set_union new_ old) (set_diff new_ old) in
    limit_ start start,

is_passive = e -> e.expr == [],
is_sym = sym p -> (not (is_passive p)) and ((p.expr).head == sym),

# Kilbury Parsing, from http://www.cs.rit.edu/~swm/cs561/Ljunglof-2002a.pdf
build_chart = grammar tokens -> let

    edge = node sym expr -> {node=node, sym=sym, expr=expr},

    initial_chart = let
        initial_state = uncurry (j token -> set [edge j token.type []]) in
        set_empty : (tmap initial_state (zip nats tokens)),

    build_state = let
        more = e ->
            if is_passive e
            then let
            predict =
                set >>
                (tmap (p -> edge e.node p.sym (p.expr).tail))
                (dict.get_def [] e.sym grammar.left_corner_map),
            combine = 
                set >>
                (tmap (e2 -> edge e2.node e2.sym (e2.expr).tail)) >>
                (tfilter (is_sym e.sym)) >>
                set_items (dict.get e.node final_chart) in
            set_union predict combine
            else set_empty in
        limit more,

    final_chart = dict.dict (zip nats (tmap build_state initial_chart)) in
    final_chart,

passive_edge = i j sym -> {i=i, j=j, sym=sym},

passive_edges = chart -> let
    state_passives = uncurry (j state -> 
        tmap (e -> passive_edge e.node j e.sym) >>
        (tfilter is_passive) >> set_items state) in
    tjoin (tmap state_passives (dict.items chart)),

tree = sym children -> {is_leaf=False, sym=sym, children=children},
leaf = sym value -> {is_leaf=True, sym=sym, value=value},

build_trees = grammar token_dict passive_chart -> let
    edge_trees = let
        to_tuple = e -> ((e.i, e.sym), (e, trees_for e)) in
        multidict >> (tmap to_tuple) passive_chart,

    trees_for = e -> let
        prod_trees = 
            tjoin >> (tmap (p -> tmap (tree e.sym) (children p.expr e.i e.j)))
            (dict.get_def [] e.sym grammar.productions) in
        if (e.i == (e.j - 1)) and (set_has e.sym grammar.terminals)
        # this is a terminal production, add a leaf node
        then let scan_leaf = leaf e.sym (dict.get e.i token_dict).value in
        scan_leaf : prod_trees
        else prod_trees,

    children = expr i k ->
        if expr == []
        then if i == k then [[]] else []
        else if i > k
        then []
        else let
            child_trees = uncurry (e trees ->
                tmap (rest -> tmap (: rest) trees) 
                (children expr.tail e.j k)) in
            tjoin >> tjoin >> (tmap child_trees) >>
            (dict.get_def [] (i, expr.head)) edge_trees in

    edge_trees

in export ::= | grammar parse suppress tree leaf
