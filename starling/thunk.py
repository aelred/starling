import logging

from starling import error, linked_list, environment, parse, function

log = logging.getLogger(__name__)


class Thunk:

    def __init__(self, token, name, env=None):
        self.token = token
        self._name = name
        self.env = env
        self._memory = None
        self._remembers = False

    def eval(self):
        if not self._remembers:
            log.info('eval\n%s' % self.token)
            self._memory = _evaluate(self.token, self.env)
            log.debug('%s = %s' % (self.token, self._memory))
            self._remembers = True
        return self._memory

    def __str__(self):
        return self._name


def _evaluate(token, env):
    try:
        return _evaluators[token.name](token.value, env)
    except KeyError:
        raise error.StarlingRuntimeError('Can\'t recognize %s' % token.name)


def _expression(value, env):
    func = Thunk(value[0], 'expression', env).eval()
    for arg in value[1:]:
        thunk_ = Thunk(arg, 'argument', env=env)
        func = func.apply(thunk_)
    return func


def _list(value, env):
    if value == []:
        return linked_list.empty
    else:
        head = Thunk(value[0], 'head', env)
        tail = Thunk(parse.Token('list', value[1:]), 'tail', env)
        return linked_list.List(head, tail)


def _let(value, env):
    bind_tokens = value[0]
    expr_token = value[1]

    bind_tokens.assert_is('bindings')
    expr_token.assert_is('expression')

    def get_bindings():
        it = iter(bind_tokens.value)
        while True:
            yield next(it), next(it)

    bindings = dict([(ident.value, Thunk(expr, ident.value))
                     for ident, expr in get_bindings()])

    new_env = environment.Environment(env, bindings)
    for thunk_ in bindings.values():
        thunk_.env = new_env

    return Thunk(expr_token, 'let', new_env).eval()


class _Lambda(function.Function):

    def __init__(self, value, env):
        params = value[0]
        params.assert_is('params')

        body = value[1]
        body.assert_is('expression')

        param = params.value[0]
        param.assert_is('identifier')
        self._param = param.value

        if len(params.value) > 1:
            less_params = parse.Token('params', params.value[1:])
            self._body = parse.Token('lambda', [less_params, body])
        else:
            self._body = body

        self._env = env

        function.Function.__init__(self, 'lambda')

    def _apply(self, thunk_):
        self.log.debug('param: %s\nbody:\n%s' % (self._param,
                                                 self._body))
        bindings = {self._param: thunk_}
        new_env = self._env.child(bindings)
        return Thunk(self._body, 'lambda', new_env).eval()


def _if(value, env):
    for expr in value:
        expr.assert_is('expression')
    pred = value[0]

    if Thunk(pred, 'predicate', env).eval():
        cons = value[1]
        return Thunk(cons, 'consequent', env).eval()
    else:
        alt = value[2]
        return Thunk(alt, 'alternative', env).eval()

_evaluators = {
    'expression': _expression,
    'identifier': lambda v, e: e.resolve(v),
    'list': _list,
    'string': lambda v, e: v,
    'number': lambda v, e: int(v),
    'let': _let,
    'lambda': _Lambda,
    'if': _if
}
