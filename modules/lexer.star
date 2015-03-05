let
regex = import regex,

max_by = f -> foldl1 (x y -> if (f y) > (f x) then y else x),

rule = type re ->
    {type=type, re=regex.match re},

tokenize = syntax input ->
    if input == ""
    then []
    else let
    match_types = map (r -> {match=r.re input, type=r.type}) syntax,
    matches = filter ((.match) >> (.match)) match_types,
    longest_match = max_by (r -> length r.match.str) matches,
    match_str = longest_match.match.str,
    type = longest_match.type,
    rem = longest_match.match.rem in
    if matches != []
    then {value=match_str, type=type} : (tokenize syntax rem)
    else [],

ignore = types -> filter (t -> not (types has t.type))

in export rule tokenize ignore
