let
# concise, slow defitions are commented out

node = \val left right: 
    {height = max (left.height) (right.height), val=val, left=left,
     right=right},

set_empty = {height = (0-1)},

balance = \n: ((n.left).height) - ((n.right).height),

ch_val = \val n: node val (n.left) (n.right),
ch_left = \left n: node (n.val) (left (n.left)) (n.right),
ch_right = \right n: node (n.val) (n.left) (right (n.right)),

tree_fold = \f init n: let
    tf = tree_fold f init in
    if n = set_empty
    then init
    else f n (tf (n.left)) (tf (n.right)),

if_not_empty = \n f: if n = set_empty then id else f,

tree_walk = \fl fr base_case empty_case x: let
    f = \n l r:
        if x < (n.val)
        then fl l n
        else if x > (n.val)
        then fr r n
        else base_case n in
    tree_fold f empty_case,

pred = \n: head >> set_reverse (n.left),
succ = \n: head >> set_items (n.right),

rotate_left = \n: ch_left (\l: ch_right (const l) n) (n.right),
rotate_right = \n: ch_right (\r: ch_left (const r) n) (n.left),

balance_left = \i n: if (balance n)<(0-i) then rotate_left n else n,
balance_right = \i n: if (balance n)>i then rotate_right n else n,

rebalance_left = (balance_right 1) >> (ch_left (balance_left 0)),
rebalance_right = (balance_left 1) >> (ch_right (balance_right 0)),

set = foldr set_add set_empty,

set_size = tree_fold (\n l r: 1 + l + r) 0,

# set_items = tree_fold (\n l r: join [l, [n.val], r]) [],
set_items = \n: 
    if n = set_empty
    then []
    else cat (set_items (n.left)) 
             ((n.val) : (set_items (n.right))),

# set_reverse = tree_fold (\n l r: join [r, [n.val], l]) [],
set_reverse = \n: 
    if n = set_empty
    then []
    else cat (set_items (n.right)) 
             ((n.val) : (set_items (n.left))),
    
# set_has = tree_walk const const (const True) False,
set_has = \x n:
    if n = set_empty
    then False
    else if x < (n.val)
    then set_has x (n.left)
    else if x > (n.val)
    then set_has x (n.right)
    else True,

# set_add = \x: let
#     left_case = \l: rebalance_left >> (ch_left >> const l),
#     right_case = \r: rebalance_right >> (ch_right >> const r) in
#     tree_walk left_case right_case id (node x set_empty set_empty) x,
set_add = \x n:
    if n = set_empty
    then node x set_empty set_empty
    else if x < (n.val)
    then rebalance_left (ch_left (set_add x) n)
    else if x > (n.val)
    then rebalance_right (ch_right (set_add x) n)
    else n,

set_add_all = flip (foldr set_add),

set_rem = let
    left_case = \l n: (if_not_empty l rebalance_left) (ch_left (const l) n),
    right_case = \r n: (if_not_empty r rebalance_right) (ch_right (const r) n),
    remove = \n: let
        swap_val = if (n.left) != set_empty then pred n else succ n,
        swap_rem = set_rem swap_val n in
        if ((n.left) = set_empty) or ((n.right) = set_empty)
        then if (n.left) != set_empty
        then n.left
        else n.right
        else ch_val swap_val swap_rem
    in
    tree_walk left_case right_case remove set_empty in 

export set_empty set set_size set_items set_has set_add set_add_all set_rem
