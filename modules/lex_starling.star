let
lexer = import lexer,
rule = lexer.rule,

enum let_ in_ enum_ lambda colon comma dot equals,
enum lpar rpar llist rlist lobj robj,
enum prefix_id infix_id space number string char,

syntax = [
    rule let_ "let",
    rule in_ "in",
    rule enum_ "enum",
    rule lambda "\\\\",
    rule colon ":",
    rule comma ",",
    rule dot "\\.",
    rule equals "=",
    rule lpar "\\(",
    rule rpar "\\)",
    rule llist "\\[",
    rule rlist "\\]",
    rule lobj "\\{",
    rule robj "\\}",
    rule space "\\s+",
    rule infix_id "[-+*/=<>?:@!]+|and|or|mod|pow|has",
    rule prefix_id "[_[:alpha:]]\\w*",
    rule number "\\d+",
    # "(\.[^\"])*"
    rule string "\"(\\\\.|[^\\\"])*\"",
    # '(\(hex|octal|a character) | non-\ character)'
    rule char "'(\\\\(x\\x\\x|[0-7]{1,3}|[^x0-7])|[^\\'])'"
],

tokenize = lexer.ignore space >> (lexer.tokenize syntax)

in
export
let_ in_ enum_ lambda colon comma dot equals 
lpar rpar llist rlist lobj robj
prefix_id infix_id string char number
tokenize
