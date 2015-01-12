import logging

from starling import star_type

log = logging.getLogger(__name__)


class Function(star_type.StarObject):
    def __init__(self, name):
        self._name = name
        self.log = log.getChild(self._name)

    def apply(self, thunk_arg):
        self.log.debug('apply:\n%s' % thunk_arg.token)
        return self._apply(thunk_arg)

    def str(self):
        return str(self)

    def __str__(self):
        return self._name


class Builtin:
    """ This behaves like a Thunk. """

    def __init__(self, *args, **kwargs):
        self._bi = _Builtin(*args, **kwargs)

    def dethunk(self):
        return self._bi


class Lambda(Function):

    def __init__(self, param, body, env):
        self._param = param
        self._body = body
        self._env = env

        Function.__init__(self, 'lambda')

    def _apply(self, thunk_):
        self.log.debug('param: %s\nbody:\n%s' % (self._param,
                                                 self._body))
        bindings = {self._param: thunk_}
        new_env = self._env.child(bindings)
        return self._body.eval(new_env)


class _Builtin(Function):

    def __init__(self, name, num_params, func):
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
        f = lambda *args: func(*[a.dethunk for a in args])
        Builtin.__init__(self, name, num_params, f)


class Const:
    """ This behaves like a Thunk. """

    def __init__(self, value):
        self._value = value

    def dethunk(self):
        return self._value
