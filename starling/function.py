import logging

log = logging.getLogger(__name__)


class Function(object):
    def __init__(self, name):
        self._name = name
        self.log = log.getChild(self._name)

    def apply(self, thunk_arg):
        self.log.debug('apply:\n%s' % thunk_arg.token)
        return self._apply(thunk_arg)

    def __str__(self):
        return self._name


class Builtin:

    def __init__(self, *args, **kwargs):
        self._bi = _Builtin(*args, **kwargs)

    def eval(self):
        return self._bi


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
        f = lambda *args: func(*[a.eval for a in args])
        Builtin.__init__(self, name, num_params, f)


class Const:

    def __init__(self, value):
        self._value = value

    def eval(self):
        return self._value
