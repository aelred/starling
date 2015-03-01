let
dict = import dict,

# sets are dictionaries but with the value field unused
# this dummy is used for all value fields
enum dummy,

empty = {height = (0-1)},

set = foldr add empty,
size = dict.size,
items = dict.keys,
has_elem = dict.has_key,
add = x -> dict.put x dummy,
add_all = flip (foldr add),
rem = dict.rem,

union = s1 s2 -> add_all (items s2) s1,
diff = s1 s2 -> set (filter (e -> not (has_elem e s2)) (items s1)) in

export empty set size items has_elem add add_all rem union diff
