import logging

import parse
import error
import linked_list
from function import Thunk, StarlingFunction, BI, Builtin, Const

log = logging.getLogger(__name__)


class Environment:
    _env_ids = 0

    def __init__(self, parent, bindings):
        self._id = Environment._env_ids
        Environment._env_ids += 1

        self._parent = parent
        self.bindings = dict(bindings)

        self.log = log.getChild(str(self))

        if self._parent is not None:
            self.log.debug('env %s -> %s: %r' %
                           (self, self._parent, self.bindings.keys()))

    def child(self, bindings):
        return Environment(self, bindings)

    def depth(self):
        if self._parent is None:
            return 0
        else:
            return self._parent.depth() + 1

    def eval(self, token):
        self.log.info('eval\n%s' % token)
        result = self._eval(token)
        self.log.debug('%s = %s' % (token, result))
        return result

    def _eval(self, token):
        func = None

        if token.is_a('expression'):
            func = self.eval(token.value[0])
            for arg in token.value[1:]:
                func = func.apply(arg, self)
            return func
        elif token.is_a('parentheses'):
            return self.eval(token.value[0])
        elif token.is_a('identifier'):
            return self.resolve(token.value)

        if token.is_a('list'):
            return linked_list.List.build(self, token)
        elif token.is_a('string'):
            return parse.strip_wrap(token.value, '"', '"')
        elif token.is_a('number'):
            return int(token.value)
        else:
            raise error.StarlingRuntimeError('Can\'t recognize %s' % token)

    def resolve(self, name):
        env = self

        while env is not None:
            env.log.debug('resolve %s' % (name,))
            if name in env.bindings:
                return env.bindings[name].dethunk()
            else:
                env = env._parent

        raise error.StarlingRuntimeError(
            'No binding for %r:\n%r' % (name, self))

    def __str__(self):
        return 'E%s' % self._id

    def __repr__(self):
        return '%s: %s\n%r' % (self, self.bindings.keys(), self._parent)


def _let(name, value, thunk):
    new_env = Environment(value.env, {name.token.value: value})
    value.env = new_env
    thunk.env = new_env
    return thunk.dethunk()


def _letall(lets, body):
    tokens = lets.token.value

    def pairs(xs):
        it = iter(xs)
        while True:
            yield next(it), next(it)

    bindings = dict([(n.value, Thunk(t, n.value))
                     for n, t in pairs(tokens)])
    new_env = Environment(lets.env, bindings)
    for thunk in bindings.values():
        thunk.env = new_env
    return new_env.eval(body.token)


glob_env = Environment(None, {
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
    '\\': Builtin('\\', 2, lambda p, b: StarlingFunction(p.token.value, b)),
    'let': Builtin('let', 3, _let),
    'letall': Builtin('letall', 2, _letall),
    'head': BI('head', 1, lambda xs: xs().head()),
    'tail': BI('tail', 1, lambda xs: xs().tail()),
    'cons': Builtin('cons', 2, lambda x, xs: linked_list.List(x, xs))
})
