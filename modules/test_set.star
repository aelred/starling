let
set = import set,
test = import test,

?= = test.assert_equal,

set1 = set.set [1],
set2 = set.set [{x=1}, {x=5}, {x=4}, {x=10}],
set3 = set.set "hello world",
set4 = set.set (range 0 14),
enum a b c,
set5 = set.set [a, b] in

test.test [
    (set.size set.empty) ?= 0,
    (set.size set1) ?= 1,
    (set.size set2) ?= 4,
    (set.size set3) ?= 8,
    (set.size set5) ?= 2,

    (set.items set.empty) ?= [],
    (set.items set1) ?= [1],
    (set.items set2) ?= [{x=1}, {x=4}, {x=5}, {x=10}],
    (set.items set3) ?= " dehlorw",
    (set.items set5) ?= [a, b],

    (set.has_elem 10 set.empty) ?= False,
    (set.has_elem 1 set1) ?= True,
    (set.has_elem 0 set1) ?= False,
    all (map (flip set.has_elem set2) [{x=1}, {x=5}, {x=4}, {x=10}]) ?= True,
    (set.has_elem {x=3} set2) ?= False,
    (all (map (flip set.has_elem set3) "hello world")) ?= True,
    (set.has_elem 'y' set3) ?= False,

    (set.items (set.add {x=2} set.empty)) ?= [{x=2}],
    (set.items (set.add 10 set1)) ?= [1, 10],
    (set.items (set.add {x=4} set2)) ?= [{x=1}, {x=4}, {x=5}, {x=10}],
    (set.items (set.add 'a' set3)) ?= " adehlorw",
    (set.items (set.add c set5)) ?= [a, b, c],

    (set.add_all [] set3) ?= set3,
    (set.items (set.add_all (map (x -> {x=x}) (range 0 5)) set2)) ?= 
    [{x=0}, {x=1}, {x=2}, {x=3}, {x=4}, {x=5}, {x=10}],

    (set.items (set.rem 0 set.empty)) ?= [],
    (set.items (set.rem 1 set1)) ?= [],
    (set.items (set.rem {x=4} set2)) ?= [{x=1}, {x=5}, {x=10}],
    (set.items (set.rem {x=8} set2)) ?= [{x=1}, {x=4}, {x=5}, {x=10}],
    (set.items (set.rem 'o' set3)) ?= " dehlrw",
    (any (map (c -> set.has_elem c (set.rem c set3)) "hello world")) ?= False,

    # make sure sets are balanced with reasonable heights
    (set4.height >= 3) ?= True,
    (set4.height < 6) ?= True,

    (set.items (set.union set.empty set.empty)) ?= [],
    (set.items (set.union set1 set.empty)) ?= (set.items set1),
    (set.items (set.union set2 set2)) ?= (set.items set2),
    (set.items (set.union set3 (set.set "yaz"))) ?= " adehlorwyz",

    (set.items (set.diff set.empty set.empty)) ?= [],
    (set.items (set.diff set1 set.empty)) ?= (set.items set1),
    (set.items (set.diff set.empty set2)) ?= [],
    (set.items (set.diff set3 (set.set "haz"))) ?= " delorw"
]
