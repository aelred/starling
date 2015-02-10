let

node = \val left right: 
    [(max (node_height left) (node_height right)) + 1, val, left, right], 

empty = [0-1],

node_height = @0,
node_val = @1,
node_left = @2,
node_right = @3,

balance = \n: (node_height . node_left n) - (node_height . node_right n),

ch_left = \left n: node (node_val n) (left . node_left n) (node_right n),
ch_right = \right n: node (node_val n) (node_left n) (right . node_right n),

tree_fold = \f init n: let
    tf = tree_fold f init in
    if n = empty
    then init
    else f n (tf . node_left n) (tf . node_right n),

tree_walk = \fl fr base empty x: let
    f = \n l r:
        if x < (node_val n)
        then fl l n
        else if x > (node_val n)
        then fr r n
        else base n in
    tree_fold f (empty x),

rotate_left = \n: ch_left (\l: ch_right (const l) n) . node_right n,

rotate_right = \n: ch_right (\r: ch_left (const r) n) . node_left n,

set = foldr set_add empty,

set_size = tree_fold (\n l r: 1 + l + r) 0,

set_items = tree_fold (\n l r: join [l, [node_val n], r]) [],
    
set_has = tree_walk const const (const True) (const False),

set_add = let
    balance_left = \i n: if (balance n)<(0-i) then rotate_left n else n,
    balance_right = \i n: if (balance n)>i then rotate_right n else n,
    left_case = \l: 
        (balance_right 1) . (ch_left (balance_left 0)) . (ch_left . const l),
    right_case = \r: 
        (balance_left 1) . (ch_right (balance_right 0)) . (ch_right . const r) in
    tree_walk left_case right_case id (\x: node x empty empty),

set_rem = \s x: s

in export set set_size set_items set_has set_add set_rem balance
