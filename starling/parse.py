from pyparsing import StringEnd, Word, Literal, SkipTo, Keyword, QuotedString
from pyparsing import Optional, OneOrMore, Group, Suppress, Forward
from pyparsing import alphas, alphanums, nums, lineEnd, delimitedList
from pyparsing import ParseException, ParseSyntaxException

from starling import error, syntax_tree

lpar = Suppress(Literal('('))
rpar = Suppress(Literal(')'))
llist = Suppress(Literal('['))
rlist = Literal(']')
equals = Suppress(Literal('='))
comma = Suppress(Literal(','))
comment = (Literal('#') + SkipTo(lineEnd))('comment*')
number = Word(nums)('number*')

let = Suppress(Keyword('let'))
in_ = Suppress(Keyword('in'))
lambda_ = Suppress(Literal('\\'))
colon = Suppress(':')
if_ = Suppress(Keyword('if'))
then = Suppress(Keyword('then'))
else_ = Suppress(Keyword('else'))
export = Suppress(Keyword('export'))
reserved = let | in_ | lambda_ | colon | if_ | then | else_ | export

word_id = Word(alphas + '_', alphanums + '_')
infix_id = (Word('+-*/=<>?') | 'and' | 'or' | 'mod' | 'pow')('identifier')
ident = ~reserved + (word_id | infix_id)('identifier*')
string = QuotedString(quoteChar='"')('string*')

atom = Forward()
infix_expr = Group(atom + infix_id + OneOrMore(atom))('infix_expression')
infix_lpartial = Group(atom + infix_id)('infix_lpartial')
infix_rpartial = Group(infix_id + atom)('infix_rpartial')
infix_partial = infix_lpartial | infix_rpartial
expr = infix_expr | infix_partial | Group(OneOrMore(atom))('expression')

parentheses = (lpar - Optional(expr) - rpar)

empty_list = rlist('emptylist')
list_inner = Forward()
list_inner << Group(expr + ((comma + list_inner) | empty_list))('list')
linked_list = llist - (list_inner | empty_list)

binding = Group(ident + equals + expr)('binding')
bindings = Group(delimitedList(binding))('bindings')
let_expr = Group(let + bindings + in_ - expr)('let*')

lambda_inner = Forward()
lambda_inner << Group(ident + ((colon + expr) | lambda_inner))('lambda')
lambda_expr = lambda_ + lambda_inner

if_expr = Group(if_ + expr + then + expr + else_ + expr)('if')

export_expr = Group(export + OneOrMore(ident))('export')

atom << (let_expr | lambda_expr | if_expr | export_expr | number | string |
         ident | parentheses | linked_list)

grammar = (expr + StringEnd()).ignore(comment)

# speeds up parsing by memoizing
grammar.enablePackrat()


def _parse(expr):
    try:
        return grammar.parseString(expr)
    except (ParseException, ParseSyntaxException), e:
        arrow = ' ' * (e.column - 1) + '^'
        raise error.StarlingSyntaxError('\n'.join([str(e), e.line, arrow]))


def tokenize(expr):
    result = _interpret_parse_result(_parse(expr))
    return result[0]


def _interpret_parse_result(parse_result):
    # The interface for this is rubbish and doesn't offer a lot of information
    # that is internal in the class. You can see this info if you print
    # repr(parse_result).
    try:
        # Forgive me Father for I have sinned
        intern_dict = parse_result._ParseResults__tokdict
    except AttributeError:
        # This is a string, so return it
        return parse_result

    def create_token(name, value):
        if name == 'infix_expression':
            # when encoutering an infix expression, change it to prefix
            name = 'expression'
            value = [value[1], value[0]] + value[2:]
        elif name == 'infix_lpartial':
            # when encoutering an infix partial, change it to a lambda
            temp_id = create_token('identifier', '$temp_partial')
            name = 'lambda'
            value = [temp_id,
                     create_token('expression', [value[1], value[0], temp_id])]
        elif name == 'infix_rpartial':
            temp_id = create_token('identifier', '$temp_partial')
            name = 'lambda'
            value = [temp_id,
                     create_token('expression', [value[0], temp_id, value[1]])]

        # when encoutering an expression, left-recursively wrap it up
        if name == 'expression':
            if len(value) == 1:
                return value[0]
            else:
                value = [create_token('expression', value[0:-1]), value[-1]]

        return token_classes[name](value)

    def get_name(index, token):
        for name, tokens in intern_dict.items():
            if (token, index) in [tt.tup for tt in tokens]:
                return name

    tokens = []
    for i, t in enumerate(parse_result):
        tokens.append(create_token(get_name(i, t), _interpret_parse_result(t)))
    return tokens


token_classes = {
    'identifier': syntax_tree.Identifier,
    'number': syntax_tree.Number,
    'string': syntax_tree.String,
    'expression': syntax_tree.Expression,
    'emptylist': syntax_tree.EmptyList,
    'list': syntax_tree.List,
    'if': syntax_tree.If,
    'let': syntax_tree.Let,
    'bindings': syntax_tree.Bindings,
    'binding': syntax_tree.Binding,
    'lambda': syntax_tree.Lambda,
    'export': syntax_tree.Export
}
