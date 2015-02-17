from starling import star_type


def trampoline(f):
    f = f()
    while True:
        try:
            f = f()
        except TypeError:
            return f


class Thunk:

    def __init__(self, f):
        self._f = f
        self._mem = None
        # if this function is strict, eval immediately
        if getattr(self._f, '__doc__', None) == 'strict':
            self()
            self.__doc__ = 'strict'

    def __call__(self):
        if self._mem is None:
            self._mem = trampoline(self._f)
            self._f = None
        return self._mem


def True__():
    return star_type.Boolean(True)


def False__():
    return star_type.Boolean(False)


def p__():
    return lambda a: lambda: lambda b: a().add(b())


def s__():
    return lambda a: lambda: lambda b: a().sub(b())


def a__():
    return lambda a: lambda: lambda b: a().mul(b())


def d__():
    return lambda a: lambda: lambda b: a().div(b())


def mod():
    return lambda a: lambda: lambda b: a().mod(b())


def pow():
    return lambda a: lambda: lambda b: a().pow(b())


def e__():
    return lambda a: lambda: lambda b: a().eq(b())


def le__():
    return lambda a: lambda: lambda b: a().le(b())


def chr__():
    return lambda x: star_type.Char(chr(x().value))


def ord__():
    return lambda c: star_type.Number(ord(c().value))
