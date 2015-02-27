from starling import star_type
from itertools import chain


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


def _str_to_list(s):
    try:
        c = s.next()
        return star_type.Object({
            'head': Thunk(lambda: star_type.Char(c)),
            'tail': Thunk(lambda: _str_to_list(s))
        })
    except StopIteration:
        return star_type.empty_list

True_ = star_type.Boolean(True)

False_ = star_type.Boolean(False)

p__ = lambda a: lambda b: a().add(b())

s__ = lambda a: lambda b: a().sub(b())

a__ = lambda a: lambda b: a().mul(b())

d__ = lambda a: lambda b: a().div(b())

mod_ = lambda a: lambda b: a().mod(b())

pow_ = lambda a: lambda b: a().pow(b())

ee__ = lambda a: lambda b: a().eq(b())

le__ = lambda a: lambda b: a().le(b())

chr_ = lambda x: star_type.Char(chr(x().value))

ord_ = lambda c: star_type.Number(ord(c().value))

repr_ = lambda o: _str_to_list(chain(*o().repr_generator()))

str_ = lambda o: _str_to_list(chain(*o().str_generator()))
