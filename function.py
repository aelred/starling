import logging

from starling import error, linked_list, parse, thunk

log = logging.getLogger(__name__)


class Function(object):
    def __init__(self, name):
        self._name = name
        self.log = log.getChild(self._name)

    def apply(self, func_arg, param_env):
        self.log.debug('apply %r' % (func_arg,))
        thunk_ = thunk.Thunk(func_arg, env=param_env)
        return self._apply(thunk_)

    def __str__(self):
        return self._name


class StarlingFunction(Function):

    def __init__(self, param, body, name=None):
        self._param = param
        self._body = body

        name = name or 'lambda'
        Function.__init__(self, name)

    @property
    def num_params(self):
        return len(self._params)

    def _apply(self, thunk_):
        self.log.debug('param: %s\nbody:\n%s' % (self._param,
                                                 self._body.token))
        bindings = {self._param: thunk_}
        new_env = self._body.env.child(bindings)
        return thunk.Thunk(self._body.token, env=new_env).eval()


class Builtin:

    def __init__(self, *args, **kwargs):
        self._bi = _Builtin(*args, **kwargs)

    def eval(self):
        return self._bi


class _Builtin(Function):

    def __init__(self, name, num_params, func):
        self.num_params = num_params
        if num_params > 1:
            def partial(thunk_):
                f = lambda *a: func(thunk_, *a)
                return _Builtin('partial-%s' % name, num_params - 1, f)
            self._apply = partial
        else:
            self._apply = func
        Function.__init__(self, name)


class BI(Builtin):
    """ Shorthand built-in function. """

    def __init__(self, name, num_params, func):
        f = lambda *args: func(*[a.eval for a in args])
        Builtin.__init__(self, name, num_params, f)


class Const:

    def __init__(self, value):
        self._value = value

    def eval(self):
        return self._value
