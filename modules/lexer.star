let
regex = import regex,

rule = \type re:
    {type=type, re=re},

tokenize = \syntax input:
    [{
        value=input, 
        type=(map (.type) (filter (\r: regex.match r.re input) syntax))
    }]

in export rule tokenize
