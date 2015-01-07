import logging

from starling import error, linked_list

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
            log.info('eval\n%s' % self.token)
            self._memory = _evaluate(self.token, self.env)
            log.debug('%s = %s' % (self.token, self._memory))
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
        func = func.apply(arg, env)
    return func


def _list(value, env):
    if value == []:
        return linked_list.empty
    else:
        head = Thunk(value[0], 'head', env)
        tail = Thunk(parse.Token(['list'], value[1:]))
        return linked_list.List(head, tail)


_evaluators = {
    'expression': _expression,
    'identifier': lambda v, e: e.resolve(v),
    'list': _list,
    'string': lambda v, e: v.strip('"'),
    'number': lambda v, e: int(v)
}
