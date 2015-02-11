import set test in let

set_empty = set [],
set1 = set [1],
set2 = set [1, 5, 4, 10],
set3 = set "hello world" in

test . (map . uncurry assert_equal) [
    [set_size set_empty, 0],
    [set_size set1, 1],
    [set_size set2, 4],
    [set_size set3, 8],

    [set_items set_empty, []],
    [set_items set1, [1]],
    [set_items set2, [1, 4, 5, 10]],
    [set_items set3, " dehlorw"],

    [set_has 10 set_empty, False],
    [set_has 1 set1, True],
    [set_has 0 set1, False],
    [all (map (flip set_has set2) [1, 5, 4, 10]), True],
    [set_has 3 set2, False],
    [all (map (flip set_has set3) "hello world"), True],
    [set_has 'y' set3, False],

    [set_items (set_add 2 set_empty), [2]],
    [set_items (set_add 10 set1), [1, 10]],
    [set_items (set_add 4 set2), [1, 4, 5, 10]],
    [set_items (set_add 'a' set3), " adehlorw"],

    [set_items (set_rem 0 set_empty), []],
    [set_items (set_rem 1 set1), []],
    [set_items (set_rem 4 set2), [1, 5, 10]],
    [set_items (set_rem 8 set2), [1, 4, 5, 10]],
    [set_items (set_rem 'o' set3), " dehlrw"],
    [any (map (\c: set_has c (set_rem c set3)) "hello world"), False]
]
