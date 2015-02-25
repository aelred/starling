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
::= = sym expr -> [{sym=sym, expr=expr}],

# alternate between different productions
# this completely abuses left-associativity!
| = production expr -> {sym=(production.head).sym, expr=expr} : production,

# create a new grammar
# start: the top-level symbol to start the pars
# terminals: a list of terminal symbols with no productions
# productions: a list of productions, made with the ::= operator
grammar = start terminals productions -> 
    {start=start, terminals=terminals, productions=join productions},

# parse some tokens using a grammar, generating a parse tree
parse = grammar tokens -> let
    edge_trees = build_trees grammar tokens passive_chart,
    passive_chart = passive_edges final_chart,
    final_chart = build_chart grammar tokens,
    start_edge = passive_edge 0 (length tokens) grammar.start,
    results = filter (uncurry (e trees -> e == start_edge)) edge_trees in
    ((results.head)._1).head,

# remove the given symbols from the parse tree
# when used to remove top-level symbol, it will only return the first
# child of the top level symbol.
suppress = syms parse_tree -> let
    suppress_ = parse_tree -> let
        suppress_children = join (map suppress_ parse_tree.children) in
        if syms has parse_tree.sym
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
        new_ = fold set_union set_empty (map more (set_items new)) in
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
        initial_state = pair -> let
            j = pair._0, token = pair._1 in
            set [edge j token.type []] in
        set_empty : (map initial_state (zip nats tokens)),

    build_state = let
        more = e ->
            if is_passive e
            then let
            predict =
                set >>
                (map (p -> edge e.node p.sym (p.expr).tail))
                (filter (is_sym e.sym) grammar.productions),
            combine = 
                set >>
                (map (e2 -> edge e2.node e2.sym (e2.expr).tail)) >>
                (filter (is_sym e.sym)) >>
                set_items (final_chart@(e.node)) in
            set_union predict combine
            else set_empty in
        limit more,

    final_chart = map build_state initial_chart in
    final_chart,

passive_edge = i j sym -> {i=i, j=j, sym=sym},

passive_edges = chart -> let
    state_passives = j state -> 
        map (e -> passive_edge e.node j e.sym) (filter is_passive state) in
    join (map (uncurry state_passives) (zip nats (map set_items chart))),

tree = sym children -> {is_leaf=False, sym=sym, children=children},
leaf = sym value -> {is_leaf=True, sym=sym, value=value},

build_trees = grammar tokens passive_chart -> let
    edge_trees = map (e -> (e, trees_for e)) passive_chart,

    trees_for = e -> let
        prod_trees = 
            join >> (map (p -> map (tree e.sym) (children p.expr e.i e.j)))
            (filter (p -> p.sym == e.sym) grammar.productions),
        scan_trees = 
            if (e.i == (e.j - 1)) and (grammar.terminals has e.sym)
            then [leaf e.sym ((tokens@(e.i)).value)]
            else [] in
        cat prod_trees scan_trees,

    children = expr i k ->
        if expr == []
        then if i == k then [[]] else []
        else if i > k
        then []
        else let
            filter_trees = uncurry (e trees -> (e.i==i) and (e.sym==expr.head)),
            child_trees = uncurry (e trees ->
                map (rest -> map (: rest) trees) (children expr.tail e.j k)) in
            join >> join >> (map child_trees)
            (filter filter_trees edge_trees) in

    edge_trees

in export ::= | grammar parse suppress
