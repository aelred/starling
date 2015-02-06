let 

between = \x1 x2 xs: cat (take_until (=x2) . (drop_until (=x1)) xs) [x2],

flatten = fold cat [],

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

ascii = cat 
    " !#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`"
    "abcdefghijklmnopqrstuvwxyz{|}~",

digits = "0123456789",

char_to_digit = \c: 
    if c='0' then 0 else if c='1' then 1 else if c='2' then 2 else
    if c='3' then 3 else if c='4' then 4 else if c='5' then 5 else
    if c='6' then 6 else if c='7' then 7 else if c='8' then 8 else 9,

parse_int = foldl (\x c: (10 * x) + (char_to_digit c)) 0,

# interpret character sets such as [0-9a-f] and [^+-]
interp_char_set = \pat: let
    is_range = (at_least 3 pat) and (pat@1 = '-'),
    range_start = pat@0,
    range_stop = pat@2,
    get_range = between range_start range_stop ascii in
    if pat = []
    then []
    else if is_range
    then cat get_range (interp_char_set (drop 3 pat))
    else head pat : (interp_char_set (tail pat)), 

# interpret a regex pattern, identifying special characters
interp_pattern = \pat: let
    sym = head pat,
    is_op = "|*{" has, is_par = "()" has, is_all = "." has, 
    is_assert = "^$" has,
    type = 
        if is_op sym then "op" else if is_par sym then "par" 
        else if is_all sym then "all" else if (take 2 pat) = "[^" then "not" 
        else if is_assert sym then "ass" else "lit",

    char_set = let
        negate = pat@1 = '^',
        pat_dropped = drop (negate? 2 1) pat,
        # first element is allowed to be a ']', e.g. "[]]" is valid
        pat_head = head pat_dropped, pat_tail = tail pat_dropped,
        chars = pat_head : (take_until (= ']') pat_tail),
        remainder = tail (drop_until (= ']') pat_tail) in
        [type, interp_char_set chars] : (interp_pattern remainder),

    counted_rep = let
        m = parse_int . (take_until ("}," has)) . tail pat,
        rem1 = drop_until ("}," has) . tail pat,
        n_str = take_until (= '}') . tail rem1,
        n = if n_str = "" then m else parse_int n_str,
        rem2 = tail (drop_until (= '}') rem1),
        unbounded = (head rem1 = ',') and (n_str = "") in
        (type : (if unbounded then ["urep", m] else ["crep", m, n])) : 
        (interp_pattern rem2) in

    if pat = []
    then []
    else if sym = '['
    then char_set
    else if sym = '{'
    then counted_rep
    else [type, [sym]] : (interp_pattern (tail pat)),

sym_type = @0, sym_val = @1,
is_op = (= "op") . sym_type,
is_this_op = \op sym: take 2 sym = op,
is_crep = is_this_op ["op", "crep"],
is_urep = is_this_op ["op", "urep"],
rep_n = @2, rep_m = @3,
lpar = ["par", "("], rpar = ["par", ")"], 
alt = ["op", "|"], star = ["op", "*"], concat = ["op", "."],
dot = ["all", "."], start = ["ass", "^"], end = ["ass", "$"],
is_unary = \op: any [is_crep op, is_urep op, op = star],

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
        rop = any [[rpar, alt, star] has r, is_crep r, is_urep r] in
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
        else if sym = rpar then drop . (pop (not . (= lpar)))
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
start_node = (@0) . head . head, 
final_node = (@1) . head . head,
start_end = @0, transitions = @1, nodes = @2,
t_start = @0, t_end = @1, t_sym = @2,
new_node = \fa: if (nodes fa) = [] then 0 else (head (nodes fa)) + 1,
edges = \fa node: filter (\t: t_start t = node) (transitions fa),
eps = ["eps", "eps"],
all_syms = nub . (filter (not . (= eps))) . (map t_sym) . transitions,

# return all potential transition nodes given a predicate on the transition
get_trans = \p fa: (map t_end) . (filter (p . t_sym)) . (edges fa),
succ = \sym: get_trans (=sym),

succ_all = \fa sym ns: flatten (map (succ sym fa) ns),
closure = \fa sym ns: let
    closure_ = \ns visited: let
        filt_ns = filter (not . (visited has)) ns in
        if filt_ns = []
        then []
        else cat filt_ns (closure_ (succ_all fa sym filt_ns) (cat filt_ns visited)) in
    closure_ ns [],

# turn a tree into a nondeterministic finite automata (NFA)
to_nfa = \tree: let
    # accessors for NFA elements: stack of nodes and transitions
    stack = @0, in_node = @0, out_node = @1,
    # push a new pair of start/end nodes
    push = \ns nfa: [ns : (stack nfa), transitions nfa, nodes nfa],
    # pop a pair of start/end nodes
    pop = \n nfa: [(drop n) . stack nfa, transitions nfa, nodes nfa],
    # add new transitions to the automata
    add_trans = \ts nfa: [stack nfa, cat ts (transitions nfa), nodes nfa],
    # add a new node to the automata
    add_node = \nfa: [stack nfa, transitions nfa, new_node nfa : (nodes nfa)],
    # create a copy of the top subautomata
    copy = \nfa: [stack nfa@0 : (stack nfa), transitions nfa, nodes nfa],

    relabel_nfa = \nfa nfa_other: let
        offset = (head . nodes nfa_other) + 1,
        relabel = (+ offset),
        relabel_trans = \t: [relabel . t_start t, relabel . t_end t, t_sym t],
        new_start_end = [map relabel . head . start_end nfa],
        new_transitions = map relabel_trans . transitions nfa,
        new_nodes = map relabel . nodes nfa in
        [new_start_end, new_transitions, new_nodes],

    join = \nfa1 nfa2: let
        rnfa2 = relabel_nfa nfa2 nfa1,
        new_transitions = cat (transitions rnfa2) (transitions nfa1),
        new_nodes = cat (nodes rnfa2) (nodes nfa1) in
        [[], new_transitions, new_nodes],
    
    parse_tree = \node: let
        nfas = map parse_tree . children node,
        sym = label node in
        if is_leaf node
        then [[[0, 1]], [[0, 1, label node]], [1, 0]]
        # concatenate the two subautomata together
        else if sym = concat then let
        new_start_end = [[start_node (nfas@0), final_node (nfas@1)]],
        trans = [final_node (nfas@0), start_node (nfas@1), eps] in
        push new_start_end (add_trans trans (join (nfas@0) (nfas@1))),
        # loop over the subautomata
        else 

    # parse a postfix expression
    parse_pf = foldl (flip parse_sym),
    # parse a single symbol
    parse_sym = \sym nfa:
        # concatenate the two subautomata together
        if sym = concat then let
        e2 = stack nfa@0, e1 = stack nfa@1,
        trans = [[out_node e1, in_node e2, eps]] in
        push [in_node e1, out_node e2] . (pop 2) . (add_trans trans) nfa 
        # create a loop in the automata
        else if sym = star then let
        e = head . stack nfa,
        n = new_node nfa,
        trans = [[n, in_node e, eps], [out_node e, n, eps]] in
        push [n, n] . (pop 1) . (add_trans trans) . add_node nfa
        # create an alternate route in the automata
        else if sym = alt then let
        n1 = new_node nfa, n2 = n1 + 1,
        e2 = stack nfa@0, e1 = stack nfa@1,
        trans = [[n1, in_node e1, eps], [n1, in_node e2, eps], 
                 [out_node e1, n2, eps], [out_node e2, n2, eps]] in
        push [n1, n2] . (pop 2) . (add_trans trans) . add_node . add_node nfa
        # transform counted repetition into simpler form
        else if is_crep sym then let
        n = rep_n sym, m = rep_m sym in
        if n=1  # we can ignore repetitions like a{1}
        then nfa
        else parse_pf (copy nfa) [concat, ["op", "crep", n-1, m-1]] 
        # add a character transition
        else let
        n1 = new_node nfa, n2 = n1 + 1 in
        push [n1, n2] . (add_trans [[n1, n2, sym]]) . add_node . add_node nfa
    in
    if tree = []
    then [[[0, 0]], [], [0]]
    else parse_tree tree,

# turn an NFA into a deterministic finite automata (DFA)
to_dfa = \nfa: let
    epsclosure = closure nfa eps,
    syms = all_syms nfa,
    new_start = epsclosure [start_node nfa],
    new_finals = \dfa: filter (has (final_node nfa)) (nodes dfa),
    convert = \stack dfa: let 
        nodeset = head stack,
        not_empty = \t: not ((t_end t) = []),
        trans_closure = \sym: [nodeset, epsclosure (succ_all nfa sym nodeset), sym],
        new_trans = filter not_empty . (map trans_closure) syms,
        new_nodes = map t_end new_trans,
        filt_nodes = filter (not . (nodes dfa has)) new_nodes,
        new_dfa = [start_end dfa, cat new_trans (transitions dfa), nodeset : (nodes dfa)] in
        if stack = [] then dfa else convert (nub (cat filt_nodes (tail stack))) new_dfa,
    result = convert [new_start] [[[new_start, new_start]], [], []] in
    [[[start_node result, new_finals result]], transitions result, nodes result],

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
        else [new_node, (final_node dfa) has new_node, False],

    # find first node, given '^' symbols
    fst_node = let
        start_trans = \node: let
            s = succ start dfa node in
            if s = [] then node else start_trans . head s in
        start_trans . start_node dfa,
    
    result = foldl mdfa [fst_node, False, False] str,

    # find last node, given '$' symbols
    end_node = let
        end_trans = \node: let
            e = succ end dfa node in
            if e = [] then node else end_trans . head e in
        end_trans . node result in

    if (final_node dfa) has fst_node
    then True
    else (not . is_fail result) and ((final_node dfa) has end_node),

# take a pattern and return a function that will match strings
match = match_dfa . to_dfa . nfa,

nfa = to_nfa . to_tree . to_postfix . add_concat . interp_pattern

in 
export match add_concat to_postfix to_nfa nfa interp_pattern interp_char_set
parse_int is_crep sym_match to_tree
