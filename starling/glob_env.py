from starling.star_type import Char, Number


p__ = lambda a: lambda b: a().add(b())

s__ = lambda a: lambda b: a().sub(b())

a__ = lambda a: lambda b: a().mul(b())

d__ = lambda a: lambda b: a().div(b())

mod_ = lambda a: lambda b: a().mod(b())

pow_ = lambda a: lambda b: a().pow(b())

ee__ = lambda a: lambda b: a().eq(b())

le__ = lambda a: lambda b: a().le(b())

chr_ = lambda x: Char(chr(x().value))

ord_ = lambda c: Number(ord(c().value))
