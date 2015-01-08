from pyparsing import StringEnd, Word, Literal, SkipTo, Keyword
from pyparsing import Optional, OneOrMore, ZeroOrMore, Group, Suppress, Forward
from pyparsing import alphas, alphanums, nums, lineEnd, quotedString
from pyparsing import ParseException, ParseSyntaxException

from starling import error

lpar = Suppress(Literal('('))
rpar = Suppress(Literal(')'))
llist = Suppress(Literal('['))
rlist = Suppress(Literal(']'))
comment = (Literal('#') + SkipTo(lineEnd))('comment*')
number = Word(nums)('number*')

let = Suppress(Keyword('let'))
in_ = Suppress(Keyword('in'))
lambda_ = Suppress(Keyword('\\'))
colon = Suppress(':')
if_ = Suppress(Keyword('if'))
then = Suppress(Keyword('then'))
else_ = Suppress(Keyword('else'))
reserved = let | in_ | lambda_ | colon | if_ | then | else_

word_id = Word(alphas + '_', alphanums + '_')
asc_id = Word('+-*/=<>?')
ident = ~reserved + (word_id | asc_id)('identifier*')
string = quotedString('string*')

atom = Forward()('atom*')
linked_list = llist + Group(ZeroOrMore(atom))('list*') + rlist
expr = Group(OneOrMore(atom))('expression*')
parentheses = (lpar - Optional(expr) - rpar)

binding = ident + atom
bindings = Group(OneOrMore(binding))('bindings')
let_expr = Group(let + bindings + in_ - expr)('let*')

params = Group(OneOrMore(ident))('params')
lambda_expr = Group(lambda_ + params + colon - expr)('lambda*')

if_expr = Group(if_ + expr + then + expr + else_ + expr)('if')

atom << (let_expr | lambda_expr | if_expr | number | string | ident |
         parentheses | linked_list)

grammar = (Optional(expr) + StringEnd()).ignore(comment)

# speeds up parsing by memoizing
grammar.enablePackrat()


def _parse(expr):
    try:
        return grammar.parseString(expr)
    except (ParseException, ParseSyntaxException), e:
        arrow = ' ' * (e.column - 1) + '^'
        raise error.StarlingSyntaxError('\n'.join([str(e), e.line, arrow]))


def tokenize(expr):
    return _interpret_parse_result(_parse(expr))


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

    def get_names(index, token):
        for name, tokens in intern_dict.items():
            if (token, index) in [tt.tup for tt in tokens]:
                yield name

    tokens = []
    for i, t in enumerate(parse_result):
        tokens.append(Token(get_names(i, t), _interpret_parse_result(t)))
    return tokens


class Token:

    def __init__(self, names, value):
        self.names = set(names)
        self.value = value

    def assert_is(self, name):
        assert name in self.names, '%r not in %r' % (name, list(self.names))

    def __eq__(self, other):
        return self.names == other.names and self.value == other.value

    def __repr__(self):
        return 'Token(%r, %r)' % (list(self.names), self.value)


def display(obj):
    try:
        obj.eval_str
    except AttributeError:
        if obj is None:
            return ''
        elif isinstance(obj, basestring):
            return '"%s"' % obj
        else:
            return str(obj)
    else:
        return obj.eval_str()
