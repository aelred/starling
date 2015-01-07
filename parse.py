from pyparsing import StringEnd, Word, Literal, Forward, CharsNotIn, SkipTo
from pyparsing import Optional, OneOrMore, ZeroOrMore, Group, Suppress
from pyparsing import alphas, alphanums, nums, oneOf, lineEnd, quotedString

lpar = Suppress(Literal('('))
rpar = Suppress(Literal(')'))
llist = Suppress(Literal('['))
rlist = Suppress(Literal(']'))
comment = (Literal('#') + SkipTo(lineEnd))('comment*')
number = Word(nums)('number*')
ident = (Word(alphas + '_', alphanums + '_') | Word('+-*/=<>\\'))('identifier*')
string = quotedString('string*')

atom = Forward()('atom*')
linked_list = llist + Group(ZeroOrMore(atom))('list*') + rlist
expr = Group(OneOrMore(atom))('expression*')
parentheses = (lpar - expr - rpar)
atom << (number | string | ident | parentheses | linked_list)

grammar = (ZeroOrMore(expr) + StringEnd()).ignore(comment)

def tokenize(expr):
    parse_result = grammar.parseString(expr)
    return _interpret_parse_result(parse_result)


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

    def is_a(self, name):
        return name in self.names

    def __eq__(self, other):
        return self.names == other.names and self.value == other.value

    def __repr__(self):
        return 'Token(%r, %r)' % (list(self.names), self.value)


def display(obj):
    try:
        return obj.eval_str()
    except AttributeError:
        if obj is None:
            return ''
        elif isinstance(obj, basestring):
            return '"%s"' % obj
        else:
            return str(obj)
