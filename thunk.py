import logging

from starling import error, linked_list, environment, parse, function

log = logging.getLogger(__name__)


class Thunk:

    def __init__(self, token, name=None, env=None):
        self.token = token
        self._name = name or 'thunk'
        self.env = env
        self._memory = None
        self._remembers = False

    def eval(self):
        if not self._remembers:
            log.info('eval\n%s' % self.token.names)
            self._memory = _evaluate(self.token, self.env)
            log.debug('%s = %s' % (self.token.names, self._memory))
            self._remembers = True
        return self._memory


def _evaluate(token, env):
    for name in token.names:
        try:
            return _evaluators[name](token.value, env)
        except KeyError:
            pass

    raise error.StarlingRuntimeError('Can\'t recognize %s' % token.names)


def _expression(value, env):
    func = Thunk(value[0], env=env).eval()
    for arg in value[1:]:
        arg.assert_is('atom')
        thunk_ = Thunk(arg, env=env)
        func = func.apply(thunk_)
    return func


def _list(value, env):
    if value == []:
        return linked_list.empty
    else:
        value[0].assert_is('atom')
        head = Thunk(value[0], 'head', env)
        tail = Thunk(parse.Token(['list'], value[1:]), 'tail', env)
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

    return Thunk(expr_token, env=new_env).eval()


class Lambda(function.Function):

    def __init__(self, value, env):
        value[0].assert_is('identifier')
        value[1].assert_is('expression')

        self._param = value[0].value
        self._body = value[1]
        self._env = env

        function.Function.__init__(self, 'lambda')

    def _apply(self, thunk_):
        self.log.debug('param: %s\nbody:\n%s' % (self._param,
                                                 self._body))
        bindings = {self._param: thunk_}
        new_env = self._env.child(bindings)
        return Thunk(self._body, env=new_env).eval()

_evaluators = {
    'expression': _expression,
    'identifier': lambda v, e: e.resolve(v),
    'list': _list,
    'string': lambda v, e: v.strip('"'),
    'number': lambda v, e: int(v),
    'let': _let,
    'lambda': Lambda
}
