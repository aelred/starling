let 

between = \x1 x2 xs: cat (take_until (=x2) . (drop_until (=x1)) xs) [x2],

nub = \l: let
    nub_ = \xs ls:
        if xs = []
        then []
        else if ls has (head xs)
        then nub_ (tail xs) ls
        else head xs : (nub_ (tail xs) ((head xs) : ls)) in
    nub_ l [],

at_least = \n xs:
    if n = 0 
    then True
    else if xs = []
    then False
    else at_least (n-1) (tail xs),

starts_with = \xs sub: 
    if sub = []
    then True
    else if xs = []
    then False
    else if (head xs) = (head sub)
    then starts_with (tail xs) (tail sub)
    else False,

ascii = cat 
    " !#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`"
    "abcdefghijklmnopqrstuvwxyz{|}~",

char_to_digit = \c: 
    if c='0' then 0 else if c='1' then 1 else if c='2' then 2 else
    if c='3' then 3 else if c='4' then 4 else if c='5' then 5 else
    if c='6' then 6 else if c='7' then 7 else if c='8' then 8 else 9,

parse_int = foldl (\x c: (10 * x) + (char_to_digit c)) 0,

upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
lower = "abcdefghijklmnopqrstuvwxyz",
alpha = cat upper lower,
digit = "0123456789",
xdigit = cat digit "ABCDEFabcdef",
alnum = cat alpha digit,
punct = "!#$%&'()*+,-./:;<=>?@[\]^_`{|}~",
space = " ",
cntrl = "",
graph = cat alnum punct,
print = " " : graph,

char_classes = [
    ["[:upper:]", upper], ["[:lower:]", lower], ["[:alpha:]", alpha], 
    ["[:digit:]", digit], ["[:xdigit:]", xdigit], ["[:alnum:]", alnum], 
    ["[:punct:]", punct], ["[:space:]", space], ["[:cntrl:]", cntrl], 
    ["[:graph:]", graph], ["[:print:]", print]
],

# interpret bracket expressions such as [0-9a-f] and [^+-]
interp_bracket_expr = \pat: let
    bexpr = @0, remainder = @1,
    add_bexpr = \new_bexpr result: 
        [cat new_bexpr . bexpr result, remainder result],
    interp = \pat: let
        is_range = (at_least 4 pat) and (pat@1 = '-'),
        class_matches = filter (\cl: starts_with pat (cl@0)) char_classes,
        class = head class_matches,
        range_start = pat@0,
        range_stop = pat@2,
        get_range = between range_start range_stop ascii in
        if head pat = ']'
        then ["", tail pat]
        else if is_range
        then add_bexpr get_range . interp (drop 3 pat)
        else if class_matches != []
        then add_bexpr (class@1) . interp (drop (length (class@0)) pat)
        else add_bexpr [head pat] . interp (tail pat) in
    # first element is allowed to be a ']', e.g. "[]]" is valid
    if head pat = ']' 
    then add_bexpr [head pat] . interp (tail pat)
    else interp pat,

# interpret a regex pattern, identifying special characters
interp_pattern = \pat: let
    sym = head pat,
    is_op = "|*{?+" has, is_par = "()" has, is_all = "." has, 
    is_assert = "^$" has,
    type = 
        if "|*{?+" has sym then "op" else if "()" has sym then "par" 
        else if sym = '.' then "all" else if (take 2 pat) = "[^" then "not" 
        else if "^$" has sym then "ass" else "lit",

    bracket_expr = let
        negate = pat@1 = '^',
        pat_dropped = drop (negate? 2 1) pat,
        result = interp_bracket_expr pat_dropped,
        bexpr = result@0, remainder = result@1 in
        [type, bexpr] : (interp_pattern remainder),

    counted_rep = let
        m = parse_int . (take_until ("}," has)) . tail pat,
        rem1 = drop_until ("}," has) . tail pat,
        n_str = take_until (= '}') . tail rem1,
        n = if take 1 rem1 = "}" or (n_str = "") then m else parse_int n_str,
        rem2 = tail (drop_until (= '}') rem1),
        unbounded = (head rem1 = ',') and (n_str = "") in
        (type : (if unbounded then ["urep", m] else ["crep", m, n])) : 
        (interp_pattern rem2) in

    if pat = []
    then []
    else if sym = '\'
    then [type, [pat@1]] : (interp_pattern (tail . tail pat))
    else if sym = '['
    then bracket_expr
    else if sym = '{'
    then counted_rep
    else [type, [sym]] : (interp_pattern (tail pat)),

sym_type = @0, sym_val = @1,
is_op = (= "op") . sym_type,
is_this_op = \op sym: take 2 sym = op,
is_crep = is_this_op ["op", "crep"],
is_urep = is_this_op ["op", "urep"],
rep_m = @2, rep_n = @3,
lpar = ["par", "("], rpar = ["par", ")"], 
alt = ["op", "|"], star = ["op", "*"], concat = ["op", "."],
opt = ["op", "?"], plus = ["op", "+"],
dot = ["all", "."], ass_start = ["ass", "^"], end = ["ass", "$"],
is_unary = \op: any [is_crep op, is_urep op, [star, opt, plus] has op],

# return true if a character matches the given symbol
sym_match = \sym char: 
    any [
        sym = dot, 
        (sym_type sym = "lit") and ((sym_val sym) has char),
        (sym_type sym = "not") and (not ((sym_val sym) has char))
    ],

# add explicit concat symbol
add_concat = \pat:
    let concatenate = \xs accum: let 
        l = xs@0, r = xs@1,
        lop = [lpar, alt] has l,
        rop = (is_op r) or (r = rpar) in
        if lop or rop
        then r : accum 
        else concat : (r : accum) in
    if pat = []
    then []
    else head pat : (fold concatenate [] (zip pat (tail pat))),

# transform a regular expression to postfix form
to_postfix = \pat: let 
    # operator precedence
    prec = \sym: if is_unary sym then 3 else if sym = concat then 2 else 1,
    # methods to access state elements
    stack = @0, out = @1,
    # push a symbol onto the stack
    push = \sym state: [sym : (stack state), out state],
    # output a symbol
    output = \sym state: [stack state, sym : (out state)],
    # drop the top stack symbol
    drop = \state: [tail . stack state, out state],
    # pop symbols off the stack onto output while they satisfy p
    pop = \p state: let
        stack_popped = take_while p . stack state,
        stack_remainder = drop_while p . stack state in
        [stack_remainder, cat (reverse stack_popped) (out state)],
    # fold function
    pf = \sym: 
        # push '(' onto the stack
        if sym = lpar then push sym 
        # pop symbols to output until a '(', then remove the '('
        else if sym = rpar then drop . (pop (!= lpar))
        # pop higher-precedence operators to output, then push operator
        else if is_op sym
        then push sym . (pop \op: is_op op and ((prec sym) < (prec op)))
        # otherwise, push identifier to output
        else output sym,
    pf_fold = fold pf [[], []] (reverse pat) in
    # fold over pattern, then append stack to output
    cat (reverse . out pf_fold) (stack pf_fold),

# tree accessors
is_leaf = ("leaf" =) . (@0), label = @1, children=@2,

# transform a postfix regex into a tree
to_tree = \pfix: let
    subtree = \stack sym:
        if is_op sym then 
            if is_unary sym 
            then ["node", sym, [head stack]] : (tail stack)
            else ["node", sym, reverse (take 2 stack)]: (drop 2 stack)
        else ["leaf", sym] : stack in 
    head (foldl subtree [[]] pfix),

# NFA/DFA accessors
start = @0, final = @1, transitions = @2, nodes = @3,
t_start = @0, t_end = @1, t_sym = @2,
new_node = \fa: if (nodes fa) = [] then 0 else (head (nodes fa)) + 1,
edges = \fa node: filter (\t: t_start t = node) (transitions fa),
eps = ["eps", "eps"],
all_syms = nub . (filter (!= eps)) . (map t_sym) . transitions,

# return all potential transition nodes given a predicate on the transition
get_trans = \p fa: (map t_end) . (filter (p . t_sym)) . (edges fa),
succ = \sym: get_trans (=sym),

succ_all = \fa sym ns: join (map (succ sym fa) ns),
closure = \fa sym ns: let
    closure_ = \ns visited: let
        filt_ns = filter (not . (visited has)) ns in
        if filt_ns = []
        then []
        else cat filt_ns (closure_ (succ_all fa sym filt_ns) (cat filt_ns visited)) in
    closure_ ns [],

# turn a tree into a nondeterministic finite automata (NFA)
to_nfa = \tree: let
    # change the start/end nodes of an automata
    set_start = \n nfa: [n, final nfa, transitions nfa, nodes nfa],
    set_final = \n nfa: [start nfa, n, transitions nfa, nodes nfa],
    # add new transitions to the automata
    add_trans = \ts nfa: [start nfa, final nfa, cat ts (transitions nfa), nodes nfa],
    # an empty nfa
    empty = [0, 0, [], [0]],

    relabel_nfa = \nfa nfa_other: let
        offset = (head . nodes nfa_other) + 1,
        relabel = (+ offset),
        relabel_trans = \t: [relabel . t_start t, relabel . t_end t, t_sym t],
        new_start = relabel . start nfa,
        new_final = relabel . final nfa,
        new_transitions = map relabel_trans . transitions nfa,
        new_nodes = map relabel . nodes nfa in
        [new_start, new_final, new_transitions, new_nodes],

    join = \nfa1 nfa2: let
        rnfa2 = relabel_nfa nfa2 nfa1,
        new_transitions = cat (transitions rnfa2) (transitions nfa1),
        new_nodes = cat (nodes rnfa2) (nodes nfa1) in
        [[start nfa1, final nfa1, new_transitions, new_nodes], nfa1, rnfa2],
    
    parse_tree = \node: let
        nfas = map parse_tree . children node,
        sym = label node in
        if is_leaf node
        # basic transition
        then [0, 1, [[0, 1, label node]], [1, 0]]
        # concatenate the two subautomata together
        else if sym = concat then let
        joined = join (nfas@0) (nfas@1), 
        new_nfa = joined@0, nfa1 = joined@1, nfa2 = joined@2,
        trans = [[final nfa1, start nfa2, eps]] in
        set_final (final nfa2) (add_trans trans new_nfa)
        # loop over the subautomata
        else if sym = star then let
        joined = join [0, 0, [], [0]] (nfas@0),
        new_nfa = joined@0, sub = joined@2 in
        add_trans [[0, start sub, eps], [final sub, 0, eps]] new_nfa
        # alternate between subautomata
        else if sym = alt then let
        join1 = join [0, 1, [], [1, 0]] (nfas@0),
        new_nfa1 = join1@0, nfa1 = join1@2,
        join2 = join new_nfa1 (nfas@1),
        new_nfa2 = join2@0, nfa2 = join2@2,
        trans = [[0, start nfa1, eps], [0, start nfa2, eps],
                 [final nfa1, 1, eps], [final nfa2, 1, eps]] in
        add_trans trans new_nfa2 
        # optionally accept the subautomata
        else if sym = opt then let
        joined = join [0, 1, [[0, 1, eps]], [1, 0]] (nfas@0),
        new_nfa = joined@0, sub = joined@2 in
        add_trans [[0, start sub, eps], [final sub, 1, eps]] new_nfa
        # one or more repetitions
        else if sym = plus then let
        child = children node in
        parse_tree ["node", concat, ["node", star, child] : child]
        # handle counted repetitions like a{3,5}
        else if is_crep sym then let
        m = rep_m sym, n = rep_n sym, child = children node,
        next_rep = ["node", ["op", "crep", m=0? 0 (m-1), n-1], child],
        recurse_tree = ["node", concat, next_rep : child] in
        if n = 0 
        then empty 
        else parse_tree (m=0? ["node", opt, [recurse_tree]] recurse_tree)
        # handle unbounded repetitions like a{3,}
        else let
        m = rep_m sym,
        next_rep = ["node", ["op", "urep", m-1], children node] in
        if m = 0
        then parse_tree ["node", star, children node]
        else parse_tree ["node", concat, next_rep : (children node)] in

    if tree = [] then empty else parse_tree tree,

# turn an NFA into a deterministic finite automata (DFA)
to_dfa = \nfa: let
    epsclosure = closure nfa eps,
    syms = all_syms nfa,
    new_start = epsclosure [start nfa],
    new_finals = \dfa: filter (has (final nfa)) (nodes dfa),
    convert = \stack dfa: let 
        nodeset = head stack,
        not_empty = \t: (t_end t) != [],
        trans_closure = \sym: [nodeset, epsclosure (succ_all nfa sym nodeset), sym],
        new_trans = filter not_empty . (map trans_closure) syms,
        new_nodes = map t_end new_trans,
        filt_nodes = filter (not . (nodes dfa has)) new_nodes,
        new_dfa = [start dfa, final dfa, cat new_trans (transitions dfa), nodeset : (nodes dfa)] in
        if stack = [] then dfa else convert (nub (cat filt_nodes (tail stack))) new_dfa,
    result = convert [new_start] [new_start, new_start, [], []] in
    [start result, new_finals result, transitions result, nodes result],

# match a string using a DFA
match_dfa = \dfa str: let
    # define state accessors 
    node = @0, is_match = @1, is_fail = @2,

    mdfa = \state char: let
        new_nodes = get_trans (\sym: sym_match sym char) dfa . node state,
        new_node = head new_nodes in
        if (is_match state) or (is_fail state)
        then state 
        # if no next node in DFA, this is not a match
        else if new_nodes = []
        then [node state, False, True]
        # if final DFA node found, this is a match
        else [new_node, (final dfa) has new_node, False],

    # find first node, given '^' symbols
    fst_node = let
        start_trans = \node: let
            s = succ ass_start dfa node in
            if s = [] then node else start_trans . head s in
        start_trans . start dfa,
    
    result = foldl mdfa [fst_node, False, False] str,

    # find last node, given '$' symbols
    end_node = let
        end_trans = \node: let
            e = succ end dfa node in
            if e = [] then node else end_trans . head e in
        end_trans . node result in

    if (final dfa) has fst_node
    then True
    else (not . is_fail result) and ((final dfa) has end_node),

# take a pattern and return a function that will match strings
match = match_dfa . to_dfa . nfa,

nfa = to_nfa . to_tree . lex_pattern,

lex_pattern = to_postfix . add_concat . interp_pattern

in 
export match add_concat to_postfix to_nfa nfa interp_pattern interp_char_set
parse_int is_crep sym_match to_tree to_dfa lex_pattern interp_bracket_expr
