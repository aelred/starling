from starling import environment, linked_list
from starling.function import Const, BI, Builtin

glob_env = environment.Environment(None, {
    'False': Const(False),
    'True': Const(True),
    '+': BI('+', 2, lambda a, b: a() + b()),
    '-': BI('-', 2, lambda a, b: a() - b()),
    '*': BI('*', 2, lambda a, b: a() * b()),
    '/': BI('/', 2, lambda a, b: a() / b()),
    'mod': BI('mod', 2, lambda a, b: a() % b()),
    '=': BI('=', 2, lambda a, b: a() == b()),
    '>': BI('>', 2, lambda a, b: a() > b()),
    '<': BI('<', 2, lambda a, b: a() < b()),
    'if': BI('if', 3, lambda p, c, a: c() if p() else a()),
    'head': BI('head', 1, lambda xs: xs().head()),
    'tail': BI('tail', 1, lambda xs: xs().tail()),
    'cons': Builtin('cons', 2, lambda x, xs: linked_list.List(x, xs))
})
