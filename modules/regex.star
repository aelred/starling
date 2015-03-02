let 
set = import set,
dict = import dict,
multidict = dict.multidict,

nub = l -> let
    nub_ = xs ls ->
        if xs == []
        then []
        else if ls has xs.head
        then nub_ xs.tail ls
        else xs.head : (nub_ xs.tail (xs.head : ls)) in
    nub_ l [],

at_least = n xs ->
    if n == 0 
    then True
    else if xs == []
    then False
    else at_least (n-1) xs.tail,

starts_with = xs sub -> 
    if sub == []
    then True
    else if xs == []
    then False
    else if xs.head == sub.head
    then starts_with xs.tail sub.tail
    else False,

char_to_digit = c -> (ord c) - 48,

parse_int = foldl (x c -> (10 * x) + (char_to_digit c)) 0,

# merge two sorted lists
merge = xs ys ->
    if xs == []
    then ys
    else if ys == []
    then xs
    else if xs.head < ys.head
    then xs.head : (merge xs.tail ys)
    else ys.head : (merge xs ys.tail),

in_range = char range -> (range._0 <= char) and (char <= range._1),

# helper functions that increment/decrement a character value
incr = chr >> (+1) >> ord,
decr = chr >> (-1) >> ord,

# merge a range, joining together touching ranges
merge_range = xs -> let
    x = xs.head, y = xs@1 in

    # base case
    if (xs == []) or (xs.tail == [])
    then xs
    # check if these need to merge
    else if incr x._1 >= y._0
    then merge_range ((x._0, y._1) : (xs.tail).tail)
    else x : (merge_range xs.tail),

# union two lists of ranges, like merging sorted lists
union_range = xs ys -> merge_range (merge xs ys),

# give the negation of a range
negate_range = ranges -> let
    r = ranges.head,
    negate_rec = negate_range ranges.tail,

    right_edge = 
        if negate_rec == [] 
        then '\xFF' 
        else (negate_rec.head)._1,
    
    # create two new ranges:
    # 0<---new2--->[===r===]<----new1---->[===next-range====]
    new_range1 = 
        if r._1 < '\xFF' 
        then (incr r._1, right_edge) : negate_rec.tail 
        else negate_rec.tail,
    new_range2 = 
        if r._0 > '\x00' 
        then ('\x00', decr r._0) : new_range1 
        else new_range1 in

    # negation of empty range is everything
    if ranges == []
    then all_range
    else new_range2,

# change a list of ranges into a disjoint list of ranges (no overlaps)
disjoin_range = ranges -> let
    disjoin = ranges start ends -> let
        r = ranges.head,
        next_start = r._0,
        next_end = (set.items ends).head in

        # base case
        if ranges == [] and (ends == set.empty)
        then []
        # if there are no endpoints, jump straight to next range
        else if ends == set.empty
        then disjoin ranges.tail next_start (set.add r._1 ends)

        # add everything up to the end point and remove that end point
        else if ranges == [] or (next_start > next_end)
        then let 
        disjoin_rec = disjoin ranges (incr next_end) (set.rem next_end ends) in 
        if next_end >= start
        then (start, next_end) : disjoin_rec
        else disjoin_rec 

        # add everything up to the new range and add the new range's endpoint
        else let 
        disjoin_rec = disjoin ranges.tail next_start (set.add r._1 ends) in
        if next_start > start 
        then (start, decr next_start) : disjoin_rec 
        else disjoin_rec in

    disjoin (sort ranges) '\x00' set.empty,

all_range = [('\x00', '\xFF')],

upper = [('A', 'Z')],
lower = [('a', 'z')],
alpha = [('A', 'Z'), ('a', 'z')],
digit = [('0', '9')],
xdigit = [('0', '9'), ('A', 'F'),  ('a', 'f')],
alnum = [('0', '9'), ('A', 'Z'), ('a', 'z')],
word = [('0', '9'), ('A', 'Z'), ('_', '_'), ('a', 'z')],
punct = [('!', '/'), (':', '@'), ('[', '`'), ('{', '~')],
space = [('\t', '\r'), (' ', ' ')],
cntrl = [('\x00', '\x1F'), ('\x7F', '\x7F')],
graph = [('!', '~')],
print = [(' ', '~')],

char_classes = [
    ["[:upper:]", upper], ["[:lower:]", lower], ["[:alpha:]", alpha], 
    ["[:digit:]", digit], ["[:xdigit:]", xdigit], ["[:alnum:]", alnum], 
    ["[:word:]", word], ["[:punct:]", punct], ["[:space:]", space], 
    ["[:cntrl:]", cntrl], ["[:graph:]", graph], ["[:print:]", print]
],

char_short = [
    ['u', upper], ['l', lower], ['a', alpha], ['d', digit],
    ['D', negate_range digit], ['x', xdigit], ['w', word], 
    ['W', negate_range word], ['s', space], ['S', negate_range space],
    ['p', print]
],

# interpret bracket expressions such as [0-9a-f] and [^+-]
interp_bracket_expr = pat -> let
    add_bexpr = new_bexpr result -> {
            bexpr=union_range new_bexpr result.bexpr, 
            remainder=result.remainder
        },
    interp = pat -> let
        is_range = (at_least 4 pat) and (pat@1 == '-'),
        class_matches = filter (cl -> starts_with pat (cl@0)) char_classes,
        class = class_matches.head in
        if pat.head == ']'
        then {bexpr=[], remainder=pat.tail}
        else if is_range
        then add_bexpr [(pat@0, pat@2)] >> interp (drop 3 pat)
        else if class_matches != []
        then add_bexpr (class@1) >> interp (drop (length (class@0)) pat)
        else add_bexpr [(pat.head, pat.head)] >> interp pat.tail in
    # first element is allowed to be a ']', e.g. "[]]" is valid
    if pat.head == ']' 
    then add_bexpr [(pat.head, pat.head)] >> interp pat.tail
    else interp pat,

# interpret a regex pattern, identifying special characters
interp_pattern = pat -> let
    sym = pat.head,
    type = 
        if sym == '|' then alt else if sym == '*' then star else if sym == '?'
        then opt else if sym == '+' then plus 
        else if sym == '(' then lpar else if sym == ')' then rpar 
        else if sym == '^' then ass_start else if '$' == sym then ass_end 
        else lit,

    bracket_expr = let
        negate = pat@1 == '^',
        pat_dropped = drop (negate? 2 1) pat,
        result = interp_bracket_expr pat_dropped,
        bexpr = if negate then negate_range result.bexpr else result.bexpr in
        {type=type, range=bexpr} : (interp_pattern result.remainder),

    counted_rep = let
        m_split = break ("}," has) pat.tail,
        m = parse_int m_split._0,
        rem1 = m_split._1,
        n_str = take_until (=='}') rem1.tail,
        n = if take 1 rem1 == "}" or (n_str == "") then m else parse_int n_str,
        rem2 = (drop_until (=='}') rem1).tail,
        unbounded = (rem1.head == ',') and (n_str == "") in
        (
        if unbounded 
        then {type=urep, m=m}
        else {type=crep, m=m, n=n}) : 
        (interp_pattern rem2) in

    if pat == []
    then []
    else if sym == '\\'
    then let
        class_matches = filter (cl -> (cl@0) == (pat@1)) char_short,
        class = class_matches.head in
        if class_matches != []
        then {type=lit, range=class@1} : (interp_pattern (drop 2 pat))
        else {type=type, range=[(pat@1, pat@1)]} : (interp_pattern (drop 2 pat))
    else if sym == '['
    then bracket_expr
    else if sym == '{'
    then counted_rep
    else if sym == '.'
    then {type=type, range=all_range} : (interp_pattern pat.tail)
    else if type == lit
    then {type=type, range=[(sym, sym)]} : (interp_pattern pat.tail)
    else {type=type} : (interp_pattern pat.tail),

enum alt star concat opt plus crep urep,
enum lit lpar rpar ass_start ass_end eps,

is_op = sym -> [alt, star, concat, opt, plus, crep, urep] has sym.type,
is_unary = sym -> [star, opt, plus, crep, urep] has sym.type,

# add explicit concat symbol
add_concat = pat ->
    let concatenate = xs accum -> let 
        l = xs._0, r = xs._1,
        lop = (l.type == alt) or (l.type == lpar),
        rop = (is_op r) or (r.type == rpar) in
        if lop or rop
        then r : accum 
        else {type=concat} : (r : accum) in
    if pat == []
    then []
    else pat.head : (fold concatenate [] (zip pat pat.tail)),

# transform a regular expression to postfix form
to_postfix = pat -> let 
    # operator precedence
    prec = sym -> 
        if is_unary sym then 3 else if sym.type == concat then 2 else 1,
    # push a symbol onto the stack
    push = sym state -> {stack=sym:state.stack, out=state.out},
    # output a symbol
    output = sym state -> {stack=state.stack, out=sym:state.out},
    # drop the top stack symbol
    drop = state -> {stack=(state.stack).tail, out=state.out},
    # pop symbols off the stack onto output while they satisfy p
    pop = p state -> let
        stack_split = span p state.stack in
        {stack=stack_split._1, out=cat (reverse stack_split._0) state.out},
    # fold function
    pf = sym -> 
        # push '(' onto the stack
        if sym.type == lpar then push sym 
        # pop symbols to output until a '(', then remove the '('
        else if sym.type == rpar then drop >> (pop (s -> s.type != lpar))
        # pop higher-precedence operators to output, then push operator
        else if is_op sym
        then push sym >> (pop (op -> is_op op and ((prec sym) < (prec op))))
        # otherwise, push identifier to output
        else output sym,
    pf_fold = fold pf {stack=[], out=[]} (reverse pat) in
    # fold over pattern, then append stack to output
    cat (reverse pf_fold.out) pf_fold.stack,

# tree constructor
tree = sym children -> {sym=sym, children=children},

# transform a postfix regex into a tree
to_tree = pfix -> let
    subtree = stack sym -> let
        n_params = 
            if not (is_op sym) then 0 else if is_unary sym then 1 else 2 in
        tree sym (reverse (take n_params stack)) : (drop n_params stack) in
    (foldl subtree [[]] pfix).head,

# NFA/DFA operations
automata = s f t n -> {
        start=s, final=f, trans=t, 
        trans_dict=multidict (map (tt -> (tt.start, tt)) t), nodes=n
    },
trans = start end sym -> {start=start, end=end, sym=sym},

edges = fa node -> dict.get_def [] node fa.trans_dict,
all_syms = fa -> nub >> (filter (!= {type=eps})) >> (map (.sym)) fa.trans,

# return all potential transition nodes given a predicate on the transition
get_trans = p fa -> map (.end) >> (filter (t -> p t.sym)) >> (edges fa),
succ = sym -> get_trans (==sym),

# get all literal/nonliteral transitions in an FA
lit_trans = filter (t -> (t.sym).type == lit) >> (.trans),
nonlit_trans = filter (t -> (t.sym).type != lit) >> (.trans),

succ_all = fa sym ns -> join (map (succ sym fa) ns),
closure = fa sym ns -> let
    closure_ = ns visited -> let
        filt_ns = filter (not >> (visited has)) ns,
        new_visited = cat filt_ns visited in
        if filt_ns == []
        then visited
        else closure_ (succ_all fa sym filt_ns) new_visited in
    closure_ ns [],

# turn a tree into a nondeterministic finite automata (NFA)
to_nfa = t -> let
    # change the end node of an automata
    set_final = n nfa -> automata nfa.start n nfa.trans nfa.nodes,
    # add new transitions to the automata
    add_trans = ts nfa -> 
        automata nfa.start nfa.final (cat ts nfa.trans) nfa.nodes,
    # an empty nfa
    empty = automata 0 0 [] [0],

    relabel_nfa = nfa nfa_other -> let
        offset = (nfa_other.nodes).head + 1,
        relabel = (+ offset),
        relabel_trans = t -> trans (relabel t.start) (relabel t.end) t.sym,
        new_start = relabel nfa.start,
        new_final = relabel nfa.final,
        new_trans = map relabel_trans nfa.trans,
        new_nodes = map relabel nfa.nodes in
        automata new_start new_final new_trans new_nodes,

    join = nfa1 nfa2 -> let
        rnfa2 = relabel_nfa nfa2 nfa1,
        new_trans = cat rnfa2.trans nfa1.trans,
        new_nodes = cat rnfa2.nodes nfa1.nodes,
        new_nfa = automata nfa1.start nfa1.final new_trans new_nodes in 
        {new=new_nfa, n1=nfa1, n2=rnfa2},

    epstrans = start end -> trans start end {type=eps},
    
    parse_tree = node -> let
        child = node.children,
        nfas = map parse_tree child,
        sym = node.sym in
        if sym.type == lit
        # create a transition for every range
        then let new_trans = map (r -> trans 0 1 {type=lit, range=r}) sym.range in
        automata 0 1 new_trans [1, 0]
        else if child == []
        # basic transition
        then automata 0 1 [trans 0 1 sym] [1, 0]
        # concatenate the two subautomata together
        else if sym.type == concat then let
        joined = join (nfas@0) (nfas@1), 
        new_trans = [epstrans (joined.n1).final (joined.n2).start] in
        set_final (joined.n2).final (add_trans new_trans joined.new)
        # loop over the subautomata
        else if sym.type == star then let
        joined = join empty (nfas@0) in
        add_trans [epstrans 0 (joined.n2).start,
                   epstrans (joined.n2).final 0] joined.new
        # alternate between subautomata
        else if sym.type == alt then let
        join1 = join (automata 0 1 [] [1, 0]) (nfas@0),
        join2 = join join1.new (nfas@1),
        new_trans = 
            [epstrans 0 (join1.n2).start, epstrans 0 (join2.n2).start,
             epstrans (join1.n2).final 1, epstrans (join2.n2).final 1] in
        add_trans new_trans join2.new
        # optionally accept the subautomata
        else if sym.type == opt then let
        joined = join (automata 0 1 [epstrans 0 1] [1, 0]) (nfas@0) in
        add_trans [epstrans 0 (joined.n2).start,
                   epstrans (joined.n2).final 1] joined.new
        # one or more repetitions
        else if sym.type == plus then
        parse_tree (tree {type=concat} (tree {type=star} child : child))
        # handle counted repetitions like a{3,5}
        else if sym.type == crep then let
        next_rep = tree {type=crep, m=max 0 (sym.m-1), n=sym.n-1} child,
        rec_tree = tree {type=concat} (next_rep:child) in
        if sym.n == 0 
        then empty 
        else parse_tree (sym.m==0? (tree {type=opt} [rec_tree]) rec_tree)
        # handle unbounded repetitions like a{3,}
        else let
        next_rep = tree {type=urep, m=sym.m-1} child in
        if sym.m == 0
        then parse_tree (tree {type=star} child)
        else parse_tree (tree {type=concat} (next_rep:child)) in

    if t == [] then empty else parse_tree t,

# disjoin transitions in an NFA, so no transitions 'overlap'
# e.g. [a-f] and [c-z] become [a-b], [c-f] and [g-z]
disjoin_nfa = nfa -> let
    # get a disjoint set of ranges from all symbols in NFA
    syms = all_syms nfa,
    lits = filter (s -> s.type == lit) syms,
    ranges = map (.range) lits,
    disjoined = disjoin_range ranges,

    # disjoin a particular range into a disjoint list of ranges
    disjoin = r -> filter (r2 -> in_range r2._0 r) disjoined,

    # disjoin a literal transition into a list of disjoint transitions
    disjoin_trans = t -> let
        new_trans = r -> trans t.start t.end {type=lit, range=r} in
        map new_trans (disjoin (t.sym).range),

    # disjoin all literal transitions
    new_lit_trans = join >> (map disjoin_trans) >> lit_trans nfa,
    new_trans = cat (nonlit_trans nfa) new_lit_trans in

    automata nfa.start nfa.final new_trans nfa.nodes, 

# turn an NFA into a deterministic finite automata (DFA)
to_dfa = nfa -> let
    epsclosure = closure nfa {type=eps},
    syms = all_syms nfa,
    new_start = epsclosure [nfa.start],
    new_finals = dfa -> filter (has nfa.final) dfa.nodes,
    convert = stack dfa -> let 
        nodeset = stack.head,
        not_empty = t -> t.end != [],
        trans_closure = sym -> trans nodeset (epsclosure (succ_all nfa sym nodeset)) sym,
        new_trans = filter not_empty (map trans_closure syms),
        new_nodes = map (.end) new_trans,
        filt_nodes = filter (not >> (new_dfa.nodes has)) new_nodes,
        new_dfa = automata dfa.start dfa.final (cat new_trans dfa.trans) (nodeset : dfa.nodes) in
        if stack == [] then dfa else convert (nub (cat filt_nodes stack.tail)) new_dfa,
    result = convert [new_start] (automata new_start new_start [] []) in
    automata result.start (new_finals result) result.trans result.nodes,

# minify DFA by changing union node names into fresh names
minify_dfa = dfa -> let
    new_names = zip dfa.nodes nats,
    rename = node -> ((filter (n -> n._0==node) new_names).head)._1,
    new_start = rename dfa.start,
    new_final = map rename dfa.final,
    new_trans = 
        map (t -> trans (rename t.start) (rename t.end) t.sym) dfa.trans,
    new_nodes = (unzip new_names)._1 in
    automata new_start new_final new_trans new_nodes,

# after disjoining the NFA transitions, re-combine any redundant transitions
rejoin_dfa = dfa -> let
    # join transitions with the same start and final state
    join_trans = ts -> let
        t = ts.head,
        lits = filter (t -> (t.sym).type == lit) ts,
        min_range = merge_range >> sort (map (t -> (t.sym).range) lits) in
        map (r -> trans t.start t.end {type=lit, range=r}) min_range,

    # get all literal transitions, grouped by start/end state
    group_start = dict.values dfa.trans_dict,
    group_end = dict.values >> multidict >> (map (t -> (t.end, t))),
    grouped_trans = join (map group_end group_start),

    # new transitions
    new_lit_trans = join (map join_trans grouped_trans),
    new_trans = cat (nonlit_trans dfa) new_lit_trans in
    automata dfa.start dfa.final new_trans dfa.nodes,

# return true if a character matches the given symbol
sym_match = char sym -> (sym.type == lit) and (in_range char sym.range),

# match a string using a DFA
match_dfa = dfa str -> let
    mdfa = node matched str -> let
        new_nodes = get_trans (sym_match str.head) dfa node in
        if (str == "") or (new_nodes == [])
            # if we can reach a final node, then this is a match
            then let
            end_str = (str == "") and (dfa.final has (end_trans node)) in
            if (dfa.final has node) or end_str
            then {str=matched, rem=str, match=True}
            else {match=False}
        # move to next node
        else mdfa new_nodes.head (str.head : matched) str.tail,

    # find first node, given '^' symbols
    fst_node = let
        start_trans = node -> let
            s = succ {type=ass_start} dfa node in
            if s == [] then node else start_trans s.head in
        start_trans dfa.start,

    # find last node, given '$' symbols
    end_trans = node -> let
        e = succ {type=ass_end} dfa node in
        if e == [] then node else end_trans e.head,

    result = mdfa fst_node "" str in

    if result.match
    then {match=result.match, str=reverse result.str, rem=result.rem}
    else if dfa.final has fst_node
    then {match=True, str="", rem=str}
    else {match=False},

# take a pattern and return a function that will match strings
match = match_dfa >> build_dfa,

build_dfa = rejoin_dfa >> minify_dfa >> to_dfa >> build_nfa,

build_nfa = disjoin_nfa >> to_nfa >> to_tree >> lex_pattern,

lex_pattern = to_postfix >> add_concat >> interp_pattern in 

export match build_dfa build_nfa lex_pattern
