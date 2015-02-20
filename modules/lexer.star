let
regex = import regex,

rule = \type re:
    {type=type, re=regex.match re},

tokenize = \syntax input:
    if input = ""
    then []
    else let
    match_rules = map (\r: {match=r.re input, rule=r}) syntax,
    matches = filter (\r: (r.match).match) match_rules,
    match = (matches.head).match,
    rule = (matches.head).rule,
    rem = drop (length match.str) input in
    if matches != []
    then {value=match.str, type=rule.type} : (tokenize syntax rem)
    else [],

ignore = \type: filter (\t: t.type != type)

in export rule tokenize ignore
