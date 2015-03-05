let

node = key value left right -> {
        height = (max left.height right.height) + 1, 
        key=key, value=value, left=left, right=right
    },

empty = {height = (0-1)},

balance = n -> n.left.height - n.right.height,

ch_item = item n -> node item._0 item._1 n.left n.right,
ch_left = left n -> node n.key n.value (left n.left) n.right,
ch_right = right n -> node n.key n.value n.left (right n.right),

tree_fold = f init n ->
    if n == empty
    then init
    else f n (tree_fold f init n.left) (tree_fold f init n.right),

if_not_empty = n f -> if n == empty then id else f,

tree_walk = fl fr base_case empty_case key -> let
    f = n l r ->
        if key < n.key
        then fl l n
        else if key > n.key
        then fr r n
        else base_case n in
    tree_fold f empty_case,

pred = n -> (rev_items n.left).head,
succ = n -> (items n.right).head,

rotate_left = n -> ch_left (l -> ch_right (const l) n) n.right,
rotate_right = n -> ch_right (r -> ch_left (const r) n) n.left,

balance_left = i n -> if (balance n)<(0-i) then rotate_left n else n,
balance_right = i n -> if (balance n)>i then rotate_right n else n,

rebalance_left = balance_right 1 >> (ch_left (balance_left 0)),
rebalance_right = balance_left 1 >> (ch_right (balance_right 0)),

dict = foldr (uncurry put) empty,

# dictionary with a list for every value
multidict = let
    add_elem = d pair -> let
        key = pair._0, value = pair._1,
        old_value = if has_key key d then get key d else [] in
        put key (value : old_value) d in
    foldl add_elem (dict []),

size = tree_fold (n l r -> 1 + l + r) 0,

keys = map (._0) >> items,
values = map (._1) >> items,

items = tree_fold (n l r -> join [l, [(n.key, n.value)], r]) [],
rev_items = tree_fold (n l r -> join [r, [(n.key, n.value)], l]) [],

has_key = tree_walk const const (const True) False,

# return nothing if not present in dictionary
enum nothing,
get = get_def nothing,

# tail-recursive tree search, rather than using tree_fold
get_def = default key n ->
    if n == empty
    then default
    else if key < n.key
    then get_def default key n.left
    else if key > n.key
    then get_def default key n.right
    else n.value,

put = key value -> let
    left_case = l -> rebalance_left >> (ch_left >> const l),
    right_case = r -> rebalance_right >> (ch_right >> const r),
    new_leaf = node key value empty empty in
    tree_walk left_case right_case (ch_item (key, value)) new_leaf key,

put_all = flip (foldr (uncurry put)),

rem = let
    left_case = l n -> (if_not_empty l rebalance_left) (ch_left (const l) n),
    right_case = r n -> (if_not_empty r rebalance_right) (ch_right (const r) n),
    remove = n -> let
        swap_item = if n.left != empty then pred n else succ n,
        swap_rem = rem swap_item._0 n in
        if (n.left == empty) or (n.right == empty)
        then if n.left != empty
        then n.left
        else n.right
        else ch_item swap_item swap_rem in
    tree_walk left_case right_case remove empty in

export 
dict multidict get get_def size keys values items has_key put put_all rem 
