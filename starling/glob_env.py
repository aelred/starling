from starling import star_type
from itertools import imap, chain


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

    def __call__(self):
        if self._mem is None:
            self._mem = trampoline(self._f)
            self._f = None
        return self._mem


def True_():
    return star_type.Boolean(True)


def False_():
    return star_type.Boolean(False)


def p__():
    return lambda a: lambda: lambda b: a().add(b())


def s__():
    return lambda a: lambda: lambda b: a().sub(b())


def a__():
    return lambda a: lambda: lambda b: a().mul(b())


def d__():
    return lambda a: lambda: lambda b: a().div(b())


def mod_():
    return lambda a: lambda: lambda b: a().mod(b())


def pow_():
    return lambda a: lambda: lambda b: a().pow(b())


def ee__():
    return lambda a: lambda: lambda b: a().eq(b())


def le__():
    return lambda a: lambda: lambda b: a().le(b())


def chr_():
    return lambda x: star_type.Char(chr(x().value))


def ord_():
    return lambda c: star_type.Number(ord(c().value))


def _str_to_list(s):
    try:
        c = s.next()
        return star_type.Object({
            'head': Thunk(lambda: star_type.Char(c)),
            'tail': Thunk(lambda: _str_to_list(s))
        })
    except StopIteration:
        return star_type.empty_list


def repr_():
    return lambda o: _str_to_list(chain(*o().repr_generator()))


def str_():
    return lambda o: _str_to_list(chain(*o().str_generator()))
