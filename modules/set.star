let
d = import dict,

# sets are dictionaries but with the value field unused
# this dummy is used for all value fields
enum dummy,

set_empty = {height = (0-1)},

set = foldr set_add set_empty,
set_size = d.size,
set_items = d.keys,
set_has = d.has_key,
set_add = x -> d.put x dummy,
set_add_all = flip (foldr set_add),
set_rem = d.rem,

set_union = s1 s2 -> set_add_all (set_items s2) s1,
set_diff = s1 s2 -> set (filter (e -> not (set_has e s2)) (set_items s1)) in

export
set_empty set set_size set_items set_has set_add set_add_all set_rem
set_union set_diff
