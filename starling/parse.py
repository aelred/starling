from pyparsing import StringEnd, Word, Literal, SkipTo, Keyword, QuotedString
from pyparsing import Optional, OneOrMore, Group, Suppress, Forward, Regex
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
colon = Suppress(':')
sgl_quote = Suppress(Literal("'"))

let = Suppress(Keyword('let'))
in_ = Suppress(Keyword('in'))
lambda_ = Suppress(Literal('\\'))
if_ = Suppress(Keyword('if'))
then = Suppress(Keyword('then'))
else_ = Suppress(Keyword('else'))
export = Suppress(Keyword('export'))
reserved = let | in_ | lambda_ | if_ | then | else_ | export

word_id = Word(alphas + '_', alphanums + '_')('prefix_id')
infix_id = (Word('.+-*/=<>?:') | 'and' | 'or' | 'mod' | 'pow' | 'has'
            )('infix_id')
ident = ~reserved + (infix_id | word_id)
char = sgl_quote + Regex('.')('char') + sgl_quote
string = QuotedString(quoteChar='"')('string*')

atom = Forward()
expr = Group(OneOrMore(atom))('expression')

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

atom << (let_expr | lambda_expr | if_expr | export_expr | number | char |
         string | ident | parentheses | linked_list)

grammar = (Group(expr)('script') + StringEnd()).ignore(comment)

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

    def get_name(index, token):
        for name, tokens in intern_dict.items():
            if (token, index) in [tt.tup for tt in tokens]:
                return name

    tokens = []
    for i, t in enumerate(parse_result):
        tokens.append(token_classes[get_name(i, t)]
                      (_interpret_parse_result(t)))
    return tokens


def _expr_token(value):
    # transform infix operators into prefix ones
    # use left associatino (furthest right infix operator)
    try:
        i, infix = next((i, t) for i, t in
                        reversed(list(enumerate(value)))
                        if t.is_infix)
    except StopIteration:
        pass
    else:
        # create a new prefix token
        prefix = token_classes['prefix_id'](infix.value)
        if len(value) > 2:
            # transform infix expression into prefix
            value = [prefix, _expr_token(value[0:i])] + value[i+1:]
            return _expr_token(value)
        elif len(value) == 2:
            # partial infix application
            temp_id = token_classes['prefix_id']('$temp_partial')
            if value[0] == infix:
                arg1 = temp_id
                arg2 = value[1]
            else:
                arg1 = value[0]
                arg2 = temp_id
            value = [temp_id, _expr_token([prefix, arg1, arg2])]
            return token_classes['lambda'](value)
        else:
            # a lone infix operator e.g. (+), transform to prefix
            return prefix

    if len(value) == 1:
        # redundant expression
        return value[0]
    else:
        # when encoutering an expression, left-recursively wrap it up
        return syntax_tree.Expression([_expr_token(value[0:-1]), value[-1]])


def _string_token(value):
    # change string into a linked list of chars
    if len(value) == 0:
        # empty list
        return token_classes['emptylist'](']')
    else:
        return token_classes['list']([token_classes['char'](value[0]),
                                      _string_token(value[1:])])
    return syntax_tree.String(value)

token_classes = {
    'script': syntax_tree.Script,
    'prefix_id': lambda v: syntax_tree.Identifier(v, False),
    'infix_id': lambda v: syntax_tree.Identifier(v, True),
    'number': syntax_tree.Number,
    'char': syntax_tree.Char,
    'string': _string_token,
    'expression': _expr_token,
    'emptylist': syntax_tree.EmptyList,
    'list': syntax_tree.List,
    'if': syntax_tree.If,
    'let': syntax_tree.Let,
    'bindings': syntax_tree.Bindings,
    'binding': syntax_tree.Binding,
    'lambda': syntax_tree.Lambda,
    'export': syntax_tree.Export
}
