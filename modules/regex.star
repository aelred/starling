let 

nub = \l: let
    nub_ = \xs ls:
        if xs = []
        then []
        else if ls has xs.head
        then nub_ xs.tail ls
        else xs.head : (nub_ xs.tail (xs.head : ls)) in
    nub_ l [],

at_least = \n xs:
    if n = 0 
    then True
    else if xs = []
    then False
    else at_least (n-1) xs.tail,

starts_with = \xs sub: 
    if sub = []
    then True
    else if xs = []
    then False
    else if xs.head = sub.head
    then starts_with xs.tail sub.tail
    else False,

char_to_digit = \c: (ord c) - 48,

parse_int = foldl (\x c: (10 * x) + (char_to_digit c)) 0,

crange = \start end: map chr (range start (end+1)),

upper = crange 65 90,
lower = crange 97 122,
alpha = cat upper lower,
digit = crange 48 57,
xdigit = join [digit, crange 65 70, crange 97 102],
alnum = cat alpha digit,
word = '_' : alnum,
punct = join [crange 33 47, crange 58 64, crange 91 96, crange 123 126],
space = ' ' : (crange 9 13),
cntrl = '\x7F' : (crange 0 31),
graph = crange 33 126,
print = ' ' : graph,

char_classes = [
    ["[:upper:]", upper], ["[:lower:]", lower], ["[:alpha:]", alpha], 
    ["[:digit:]", digit], ["[:xdigit:]", xdigit], ["[:alnum:]", alnum], 
    ["[:word:]", word], ["[:punct:]", punct], ["[:space:]", space], 
    ["[:cntrl:]", cntrl], ["[:graph:]", graph], ["[:print:]", print]
],

char_short = [
    ['u', {type=lit, val=upper}], ['l', {type=lit, val=lower}], 
    ['a', {type=lit, val=alpha}], ['d', {type=lit, val=digit}],
    ['D', {type=notlit, val=digit}], ['x', {type=lit, val=xdigit}],
    ['w', {type=lit, val=word}], ['W', {type=notlit, val=word}],
    ['s', {type=lit, val=space}], ['S', {type=notlit, val=space}],
    ['p', {type=lit, val=print}]
],

# interpret bracket expressions such as [0-9a-f] and [^+-]
interp_bracket_expr = \pat: let
    add_bexpr = \new_bexpr result: 
        {bexpr=cat new_bexpr result.bexpr, remainder=result.remainder},
    interp = \pat: let
        is_range = (at_least 4 pat) and (pat@1 = '-'),
        class_matches = filter (\cl: starts_with pat (cl@0)) char_classes,
        class = class_matches.head,
        get_range = map chr (range (ord (pat@0)) (ord (pat@2) + 1)) in
        if pat.head = ']'
        then {bexpr="", remainder=pat.tail}
        else if is_range
        then add_bexpr get_range >> interp (drop 3 pat)
        else if class_matches != []
        then add_bexpr (class@1) >> interp (drop (length (class@0)) pat)
        else add_bexpr [pat.head] >> interp pat.tail in
    # first element is allowed to be a ']', e.g. "[]]" is valid
    if pat.head = ']' 
    then add_bexpr [pat.head] >> interp pat.tail
    else interp pat,

# interpret a regex pattern, identifying special characters
interp_pattern = \pat: let
    sym = pat.head,
    type = 
        if sym = '|' then alt else if sym = '*' then star else if sym = '?'
        then opt else if sym = '+' then plus 
        else if sym = '(' then lpar else if sym = ')' then rpar 
        else if sym = '.' then all else if (take 2 pat) = "[^" then notlit
        else if sym = '^' then ass_start else if '$' = sym then ass_end 
        else lit,

    bracket_expr = let
        negate = pat@1 = '^',
        pat_dropped = drop (negate? 2 1) pat,
        result = interp_bracket_expr pat_dropped in
        {type=type, val=result.bexpr} : (interp_pattern result.remainder),

    counted_rep = let
        m = parse_int >> (take_until ("}," has)) pat.tail,
        rem1 = drop_until ("}," has) pat.tail,
        n_str = take_until (= '}') rem1.tail,
        n = if take 1 rem1 = "}" or (n_str = "") then m else parse_int n_str,
        rem2 = (drop_until (= '}') rem1).tail,
        unbounded = (rem1.head = ',') and (n_str = "") in
        (
        if unbounded 
        then {type=urep, m=m}
        else {type=crep, m=m, n=n}) : 
        (interp_pattern rem2) in

    if pat = []
    then []
    else if sym = '\\'
    then let
        class_matches = filter (\cl: (cl@0) = (pat@1)) char_short,
        class = class_matches.head in
        if class_matches != []
        then (class@1) : (interp_pattern (drop 2 pat))
        else {type=type, val=[pat@1]} : (interp_pattern (drop 2 pat))
    else if sym = '['
    then bracket_expr
    else if sym = '{'
    then counted_rep
    else if [lit, notlit] has type
    then {type=type, val=[sym]} : (interp_pattern pat.tail)
    else {type=type} : (interp_pattern pat.tail),

enum alt star concat opt plus crep urep,
enum all lit notlit lpar rpar ass_start ass_end eps,

is_op = \sym: [alt, star, concat, opt, plus, crep, urep] has sym.type,
is_unary = \sym: [star, opt, plus, crep, urep] has sym.type,

# return true if a character matches the given symbol
sym_match = \sym char: 
    any [
        sym.type = all, 
        (sym.type = lit) and (sym.val has char),
        (sym.type = notlit) and (not (sym.val has char))
    ],

# add explicit concat symbol
add_concat = \pat:
    let concatenate = \xs accum: let 
        l = xs._0, r = xs._1,
        lop = (l.type = alt) or (l.type = lpar),
        rop = (is_op r) or (r.type = rpar) in
        if lop or rop
        then r : accum 
        else {type=concat} : (r : accum) in
    if pat = []
    then []
    else pat.head : (fold concatenate [] (zip pat pat.tail)),

# transform a regular expression to postfix form
to_postfix = \pat: let 
    # operator precedence
    prec = \sym: 
        if is_unary sym then 3 else if sym.type = concat then 2 else 1,
    # push a symbol onto the stack
    push = \sym state: {stack=sym:state.stack, out=state.out},
    # output a symbol
    output = \sym state: {stack=state.stack, out=sym:state.out},
    # drop the top stack symbol
    drop = \state: {stack=(state.stack).tail, out=state.out},
    # pop symbols off the stack onto output while they satisfy p
    pop = \p state: let
        stack_popped = take_while p state.stack,
        stack_remainder = drop_while p state.stack in
        {stack=stack_remainder, out=cat (reverse stack_popped) state.out},
    # fold function
    pf = \sym: 
        # push '(' onto the stack
        if sym.type = lpar then push sym 
        # pop symbols to output until a '(', then remove the '('
        else if sym.type = rpar then drop >> (pop (\s: s.type != lpar))
        # pop higher-precedence operators to output, then push operator
        else if is_op sym
        then push sym >> (pop \op: is_op op and ((prec sym) < (prec op)))
        # otherwise, push identifier to output
        else output sym,
    pf_fold = fold pf {stack=[], out=[]} (reverse pat) in
    # fold over pattern, then append stack to output
    cat (reverse pf_fold.out) pf_fold.stack,

# tree constructor
tree = \sym children: {sym=sym, children=children},

# transform a postfix regex into a tree
to_tree = \pfix: let
    subtree = \stack sym: let
        n_params = 
            if not (is_op sym) then 0 else if is_unary sym then 1 else 2 in
        tree sym (reverse (take n_params stack)) : (drop n_params stack) in
    (foldl subtree [[]] pfix).head,

# NFA/DFA operations
automata = \s f t n: {start=s, final=f, trans=t, nodes=n},
trans = \start end sym: {start=start, end=end, sym=sym},

edges = \fa node: filter (\t: t.start = node) fa.trans,
all_syms = \fa: nub >> (filter (!= {type=eps})) >> (map (.sym)) fa.trans,

# return all potential transition nodes given a predicate on the transition
get_trans = \p fa: map (.end) >> (filter (\t: p t.sym)) >> (edges fa),
succ = \sym: get_trans (=sym),

succ_all = \fa sym ns: join (map (succ sym fa) ns),
closure = \fa sym ns: let
    closure_ = \ns visited: let
        filt_ns = filter (not >> (visited has)) ns,
        new_visited = cat filt_ns visited in
        if filt_ns = []
        then visited
        else closure_ (succ_all fa sym filt_ns) new_visited in
    closure_ ns [],

# turn a tree into a nondeterministic finite automata (NFA)
to_nfa = \t: let
    # change the end node of an automata
    set_final = \n nfa: automata nfa.start n nfa.trans nfa.nodes,
    # add new transitions to the automata
    add_trans = \ts nfa: 
        automata nfa.start nfa.final (cat ts nfa.trans) nfa.nodes,
    # an empty nfa
    empty = automata 0 0 [] [0],

    relabel_nfa = \nfa nfa_other: let
        offset = (nfa_other.nodes).head + 1,
        relabel = (+ offset),
        relabel_trans = \t: trans (relabel t.start) (relabel t.end) t.sym,
        new_start = relabel nfa.start,
        new_final = relabel nfa.final,
        new_trans = map relabel_trans nfa.trans,
        new_nodes = map relabel nfa.nodes in
        automata new_start new_final new_trans new_nodes,

    join = \nfa1 nfa2: let
        rnfa2 = relabel_nfa nfa2 nfa1,
        new_trans = cat rnfa2.trans nfa1.trans,
        new_nodes = cat rnfa2.nodes nfa1.nodes,
        new_nfa = automata nfa1.start nfa1.final new_trans new_nodes in 
        {new=new_nfa, n1=nfa1, n2=rnfa2},

    epstrans = \start end: trans start end {type=eps},
    
    parse_tree = \node: let
        child = node.children,
        nfas = map parse_tree child,
        sym = node.sym in
        if child = []
        # basic transition
        then automata 0 1 [trans 0 1 sym] [1, 0]
        # concatenate the two subautomata together
        else if sym.type = concat then let
        joined = join (nfas@0) (nfas@1), 
        new_trans = [epstrans (joined.n1).final (joined.n2).start] in
        set_final (joined.n2).final (add_trans new_trans joined.new)
        # loop over the subautomata
        else if sym.type = star then let
        joined = join empty (nfas@0) in
        add_trans [epstrans 0 (joined.n2).start,
                   epstrans (joined.n2).final 0] joined.new
        # alternate between subautomata
        else if sym.type = alt then let
        join1 = join (automata 0 1 [] [1, 0]) (nfas@0),
        join2 = join join1.new (nfas@1),
        new_trans = 
            [epstrans 0 (join1.n2).start, epstrans 0 (join2.n2).start,
             epstrans (join1.n2).final 1, epstrans (join2.n2).final 1] in
        add_trans new_trans join2.new
        # optionally accept the subautomata
        else if sym.type = opt then let
        joined = join (automata 0 1 [epstrans 0 1] [1, 0]) (nfas@0) in
        add_trans [epstrans 0 (joined.n2).start,
                   epstrans (joined.n2).final 1] joined.new
        # one or more repetitions
        else if sym.type = plus then
        parse_tree (tree {type=concat} (tree {type=star} child : child))
        # handle counted repetitions like a{3,5}
        else if sym.type = crep then let
        next_rep = tree {type=crep, m=max 0 (sym.m-1), n=sym.n-1} child,
        rec_tree = tree {type=concat} (next_rep:child) in
        if sym.n = 0 
        then empty 
        else parse_tree (sym.m=0? (tree {type=opt} [rec_tree]) rec_tree)
        # handle unbounded repetitions like a{3,}
        else let
        next_rep = tree {type=urep, m=sym.m-1} child in
        if sym.m = 0
        then parse_tree (tree {type=star} child)
        else parse_tree (tree {type=concat} (next_rep:child)) in

    if t = [] then empty else parse_tree t,

# turn an NFA into a deterministic finite automata (DFA)
to_dfa = \nfa: let
    epsclosure = closure nfa {type=eps},
    syms = all_syms nfa,
    new_start = epsclosure [nfa.start],
    new_finals = \dfa: filter (has nfa.final) dfa.nodes,
    convert = \stack dfa: let 
        nodeset = stack.head,
        not_empty = \t: t.end != [],
        trans_closure = \sym: trans nodeset (epsclosure (succ_all nfa sym nodeset)) sym,
        new_trans = filter not_empty >> (map trans_closure) syms,
        new_nodes = map (.end) new_trans,
        filt_nodes = filter (not >> (dfa.nodes has)) new_nodes,
        new_dfa = automata dfa.start dfa.final (cat new_trans dfa.trans) (nodeset : dfa.nodes) in
        if stack = [] then dfa else convert (nub (cat filt_nodes stack.tail)) new_dfa,
    result = convert [new_start] (automata new_start new_start [] []) in
    automata result.start (new_finals result) result.trans result.nodes,

# match a string using a DFA
match_dfa = \dfa str: let
    mdfa = \node matched str: let
        new_nodes = get_trans (\sym: sym_match sym str.head) dfa node in
        if (str = "") or (new_nodes = [])
            # if we can reach a final node, then this is a match
            then let
            end_str = (str = "") and (dfa.final has (end_trans node)) in
            if (dfa.final has node) or end_str
            then {str=matched, match=True}
            else {match=False}
        # move to next node
        else mdfa new_nodes.head (str.head : matched) str.tail,

    # find first node, given '^' symbols
    fst_node = let
        start_trans = \node: let
            s = succ {type=ass_start} dfa node in
            if s = [] then node else start_trans s.head in
        start_trans dfa.start,

    # find last node, given '$' symbols
    end_trans = \node: let
        e = succ {type=ass_end} dfa node in
        if e = [] then node else end_trans e.head,

    result = mdfa fst_node "" str in

    if result.match
    then {match=result.match, str=reverse result.str}
    else if dfa.final has fst_node
    then {match=True, str=""}
    else {match=False},

# take a pattern and return a function that will match strings
match = match_dfa >> to_dfa >> nfa,

nfa = to_nfa >> to_tree >> lex_pattern,

lex_pattern = to_postfix >> add_concat >> interp_pattern

in 
export match add_concat to_postfix to_nfa nfa interp_pattern
parse_int sym_match to_tree to_dfa lex_pattern interp_bracket_expr
