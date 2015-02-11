let
# concise, slow defitions are commented out

node = \val left right: 
    [(max (node_height left) (node_height right)) + 1, val, left, right], 

set_empty = [0-1],

node_height = @0,
node_val = @1,
node_left = @2,
node_right = @3,

balance = \n: (node_height . node_left n) - (node_height . node_right n),

ch_val = \val n: node val (node_left n) (node_right n),
ch_left = \left n: node (node_val n) (left . node_left n) (node_right n),
ch_right = \right n: node (node_val n) (node_left n) (right . node_right n),

tree_fold = \f init n: let
    tf = tree_fold f init in
    if n = set_empty
    then init
    else f n (tf . node_left n) (tf . node_right n),

if_not_empty = \n f: if n = set_empty then id else f,

tree_walk = \fl fr base_case empty_case x: let
    f = \n l r:
        if x < (node_val n)
        then fl l n
        else if x > (node_val n)
        then fr r n
        else base_case n in
    tree_fold f empty_case,

pred = head . set_reverse . node_left,
succ = head . set_items . node_right,

rotate_left = \n: ch_left (\l: ch_right (const l) n) . node_right n,
rotate_right = \n: ch_right (\r: ch_left (const r) n) . node_left n,

balance_left = \i n: if (balance n)<(0-i) then rotate_left n else n,
balance_right = \i n: if (balance n)>i then rotate_right n else n,

rebalance_left = (balance_right 1) . (ch_left (balance_left 0)),
rebalance_right = (balance_left 1) . (ch_right (balance_right 0)),

set = foldr set_add set_empty,

set_size = tree_fold (\n l r: 1 + l + r) 0,

# set_items = tree_fold (\n l r: join [l, [node_val n], r]) [],
set_items = \n: 
    if n = set_empty
    then []
    else cat (set_items (node_left n)) 
             ((node_val n) : (set_items (node_right n))),

# set_reverse = tree_fold (\n l r: join [r, [node_val n], l]) [],
set_reverse = \n: 
    if n = set_empty
    then []
    else cat (set_items (node_right n)) 
             ((node_val n) : (set_items (node_left n))),
    
# set_has = tree_walk const const (const True) False,
set_has = \x n:
    if n = set_empty
    then False
    else if x < (node_val n)
    then set_has x (node_left n)
    else if x > (node_val n)
    then set_has x (node_right n)
    else True,

# set_add = \x: let
#     left_case = \l: rebalance_left . (ch_left . const l),
#     right_case = \r: rebalance_right . (ch_right . const r) in
#     tree_walk left_case right_case id (node x set_empty set_empty) x,
set_add = \x n:
    if n = set_empty
    then node x set_empty set_empty
    else if x < (node_val n)
    then rebalance_left (ch_left (set_add x) n)
    else if x > (node_val n)
    then rebalance_right (ch_right (set_add x) n)
    else n,

set_add_all = flip (foldr set_add),

set_rem = let
    left_case = \l n: (if_not_empty l rebalance_left) (ch_left (const l) n),
    right_case = \r n: (if_not_empty r rebalance_right) (ch_right (const r) n),
    remove = \n: let
        swap_val = if (node_left n) != set_empty then pred n else succ n,
        swap_rem = set_rem swap_val n in
        if ((node_left n) = set_empty) or ((node_right n) = set_empty)
        then if (node_left n) != set_empty
        then node_left n
        else node_right n
        else ch_val swap_val swap_rem
    in
    tree_walk left_case right_case remove set_empty in 

export set_empty set set_size set_items set_has set_add set_add_all set_rem
