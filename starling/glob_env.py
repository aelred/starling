from starling import environment, linked_list, star_type
from starling.function import Const, BI, Builtin

glob_env = environment.Environment(None, {
    'False': Const(star_type.Boolean(False)),
    'True': Const(star_type.Boolean(True)),
    '+': BI('+', 2, lambda a, b: a().add(b())),
    '-': BI('-', 2, lambda a, b: a().sub(b())),
    '*': BI('*', 2, lambda a, b: a().mul(b())),
    '/': BI('/', 2, lambda a, b: a().div(b())),
    'mod': BI('mod', 2, lambda a, b: a().mod(b())),
    'pow': BI('pow', 2, lambda a, b: a().pow(b())),
    '=': BI('=', 2, lambda a, b: a().eq(b())),
    '<=': BI('<=', 2, lambda a, b: a().le(b())),
    'head': BI('head', 1, lambda xs: xs().head()),
    'tail': BI('tail', 1, lambda xs: xs().tail()),
    ':': Builtin('cons', 2, lambda x, xs: linked_list.List(x, xs)),
    'chr': BI('chr', 1, lambda x: star_type.Char(chr(x().value))),
    'ord': BI('ord', 1, lambda c: star_type.Number(ord(c().value)))
}, 'global')


def const_string(string):
    """ Create a binding for a constant string. """
    li = linked_list.empty

    # add chars of string to list
    for char in reversed(string):
        c = star_type.Char(char)
        li = linked_list.List(Const(c), Const(li))

    # return a constant that yields this string
    return Const(li)
