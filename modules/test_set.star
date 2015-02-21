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

set1 = set [1],
set2 = set [1, 5, 4, 10],
set3 = set "hello world",
set4 = set (range 0 14) in

test.test [
    (set_size set_empty) ?= 0,
    (set_size set1) ?= 1,
    (set_size set2) ?= 4,
    (set_size set3) ?= 8,

    (set_items set_empty) ?= [],
    (set_items set1) ?= [1],
    (set_items set2) ?= [1, 4, 5, 10],
    (set_items set3) ?= " dehlorw",

    (set_has 10 set_empty) ?= False,
    (set_has 1 set1) ?= True,
    (set_has 0 set1) ?= False,
    (all (map (flip set_has set2) [1, 5, 4, 10])) ?= True,
    (set_has 3 set2) ?= False,
    (all (map (flip set_has set3) "hello world")) ?= True,
    (set_has 'y' set3) ?= False,

    (set_items (set_add 2 set_empty)) ?= [2],
    (set_items (set_add 10 set1)) ?= [1, 10],
    (set_items (set_add 4 set2)) ?= [1, 4, 5, 10],
    (set_items (set_add 'a' set3)) ?= " adehlorw",

    (set_add_all [] set3) ?= set3,
    (set_items (set_add_all (range 0 5) set2)) ?= [0, 1, 2, 3, 4, 5, 10],

    (set_items (set_rem 0 set_empty)) ?= [],
    (set_items (set_rem 1 set1)) ?= [],
    (set_items (set_rem 4 set2)) ?= [1, 5, 10],
    (set_items (set_rem 8 set2)) ?= [1, 4, 5, 10],
    (set_items (set_rem 'o' set3)) ?= " dehlrw",
    (any (map (\c: set_has c (set_rem c set3)) "hello world")) ?= False,

    # make sure sets are balanced with reasonable heights
    (set4.height >= 3) ?= True,
    (set4.height < 6) ?= True
]
