let
lexer = import lexer,
rule = lexer.rule,

enum let_ in_ if_ then_ else_ enum_ lambda comma dot import_ export_,
enum lpar rpar llist rlist lobj robj,
enum colon equals,
enum prefix_id infix_id space comment bool number string char,

syntax = [
    # Literal keywords
    rule let_ "let",
    rule in_ "in",
    rule if_ "if",
    rule then_ "then",
    rule else_ "else",
    rule enum_ "enum",
    rule lambda "\\\\",
    rule comma ",",
    rule dot "\\.",
    rule import_ "import",
    rule export_ "export",
    rule lpar "\\(",
    rule rpar "\\)",
    rule llist "\\[",
    rule rlist "\\]",
    rule lobj "\\{",
    rule robj "\\}",
    rule colon ":",
    rule equals "=",
    rule bool "True|False",

    # Regex patterns
    rule space "\\s+",
    rule comment "#[^\n]*",
    rule infix_id "[-+*/=<>?:@!]+|and|or|mod|pow|has",
    rule prefix_id "[_[:alpha:]]\\w*",
    rule number "\\d+",
    # "(\.[^\"])*"
    rule string "\"(\\\\.|[^\\\"])*\"",
    # '(\(hex|octal|a character) | non-\ character)'
    rule char "'(\\\\(x\\x\\x|[0-7]{1,3}|[^x0-7])|[^\\'])'"
],

tokenize = lexer.ignore [space, comment] >> (lexer.tokenize syntax)

in
export
let_ in_ if_ then_ else_ enum_ lambda colon comma dot equals import_ export_
lpar rpar llist rlist lobj robj
prefix_id infix_id bool string char number
tokenize
