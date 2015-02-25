let
t = import startoken,
lexer = import lexer,
rule = lexer.rule,

enum space comment,

syntax = [
    # Literal keywords
    rule t.let_ "let",
    rule t.in_ "in",
    rule t.if_ "if",
    rule t.then_ "then",
    rule t.else_ "else",
    rule t.enum_ "enum",
    rule t.lambda "\\\\",
    rule t.comma ",",
    rule t.dot "\\.",
    rule t.import_ "import",
    rule t.export_ "export",
    rule t.lpar "\\(",
    rule t.rpar "\\)",
    rule t.llist "\\[",
    rule t.rlist "\\]",
    rule t.lobj "\\{",
    rule t.robj "\\}",
    rule t.colon ":",
    rule t.equals "=",
    rule t.bool "True|False",

    # Regex patterns
    rule space "\\s+",
    rule comment "#[^\n]*",
    rule t.infix_id "[-+*/=<>?:@!&|]+|and|or|mod|pow|has",
    rule t.prefix_id "[_[:alpha:]]\\w*",
    rule t.number "\\d+",
    # "(\.[^\"])*"
    rule t.string "\"(\\\\.|[^\\\"])*\"",
    # '(\(hex|octal|a character) | non-\ character)'
    rule t.char "'(\\\\(x\\x\\x|[0-7]{1,3}|[^x0-7])|[^\\'])'"
],

tokenize = lexer.ignore [space, comment] >> (lexer.tokenize syntax) in 
export tokenize
