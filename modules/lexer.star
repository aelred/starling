let
regex = import regex,

rule = \type re:
    {type=type, re=re},

tokenize = \syntax input:
    if input = ""
    then []
    else let
    match_rules = map (\r: {match=regex.match r.re input, rule=r}) syntax,
    matches = filter (\r: (r.match).match) match_rules,
    match = (matches.head).match,
    rule = (matches.head).rule,
    rem = drop (length match.str) input in
    if matches != []
    then {value=match.str, type=rule.type} : (tokenize syntax rem)
    else []

in export rule tokenize
