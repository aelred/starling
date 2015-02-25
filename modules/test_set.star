let
s = import set,
test = import test,

?= = test.assert_equal,

set_empty = s.set_empty,
set = s.set,
set_size = s.set_size,
set_items = s.set_items,
set_has = s.set_has,
set_add = s.set_add,
set_add_all = s.set_add_all,
set_rem = s.set_rem,
set_union = s.set_union,
set_diff = s.set_diff,

set1 = set [1],
set2 = set [{x=1}, {x=5}, {x=4}, {x=10}],
set3 = set "hello world",
set4 = set (range 0 14),
enum a b c,
set5 = set [a, b] in

test.test [
    (set_size set_empty) ?= 0,
    (set_size set1) ?= 1,
    (set_size set2) ?= 4,
    (set_size set3) ?= 8,
    (set_size set5) ?= 2,

    (set_items set_empty) ?= [],
    (set_items set1) ?= [1],
    (set_items set2) ?= [{x=1}, {x=4}, {x=5}, {x=10}],
    (set_items set3) ?= " dehlorw",
    (set_items set5) ?= [a, b],

    (set_has 10 set_empty) ?= False,
    (set_has 1 set1) ?= True,
    (set_has 0 set1) ?= False,
    (all (map (flip set_has set2) [{x=1}, {x=5}, {x=4}, {x=10}])) ?= True,
    (set_has {x=3} set2) ?= False,
    (all (map (flip set_has set3) "hello world")) ?= True,
    (set_has 'y' set3) ?= False,

    (set_items (set_add {x=2} set_empty)) ?= [{x=2}],
    (set_items (set_add 10 set1)) ?= [1, 10],
    (set_items (set_add {x=4} set2)) ?= [{x=1}, {x=4}, {x=5}, {x=10}],
    (set_items (set_add 'a' set3)) ?= " adehlorw",
    (set_items (set_add c set5)) ?= [a, b, c],

    (set_add_all [] set3) ?= set3,
    (set_items (set_add_all (map (x -> {x=x}) (range 0 5)) set2)) ?= 
    [{x=0}, {x=1}, {x=2}, {x=3}, {x=4}, {x=5}, {x=10}],

    (set_items (set_rem 0 set_empty)) ?= [],
    (set_items (set_rem 1 set1)) ?= [],
    (set_items (set_rem {x=4} set2)) ?= [{x=1}, {x=5}, {x=10}],
    (set_items (set_rem {x=8} set2)) ?= [{x=1}, {x=4}, {x=5}, {x=10}],
    (set_items (set_rem 'o' set3)) ?= " dehlrw",
    (any (map (c -> set_has c (set_rem c set3)) "hello world")) ?= False,

    # make sure sets are balanced with reasonable heights
    (set4.height >= 3) ?= True,
    (set4.height < 6) ?= True,

    (set_items (set_union set_empty set_empty)) ?= [],
    (set_items (set_union set1 set_empty)) ?= (set_items set1),
    (set_items (set_union set2 set2)) ?= (set_items set2),
    (set_items (set_union set3 (set "yaz"))) ?= " adehlorwyz",

    (set_items (set_diff set_empty set_empty)) ?= [],
    (set_items (set_diff set1 set_empty)) ?= (set_items set1),
    (set_items (set_diff set_empty set2)) ?= [],
    (set_items (set_diff set3 (set "haz"))) ?= " delorw"
]
