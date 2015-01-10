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
    '>': BI('>', 2, lambda a, b: a().gt(b())),
    '<': BI('<', 2, lambda a, b: a().lt(b())),
    'head': BI('head', 1, lambda xs: xs().head()),
    'tail': BI('tail', 1, lambda xs: xs().tail()),
    'cons': Builtin('cons', 2, lambda x, xs: linked_list.List(x, xs))
})
