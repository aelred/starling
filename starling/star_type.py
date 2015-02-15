from starling import error


class StarType(object):
    def str_generator(self):
        """
        Return generator for string representation.

        Useful for representing potentially infinite objects.
        Must implement one of str_generator or str.
        """
        yield self.str()

    def str(self):
        """"
        Return string representation.

        Must implement one of str_generator or str.
        """
        return ''.join(self.str_generator())


class Object(StarType):
    def __init__(self, value):
        self._value = value

    @property
    def value(self):
        return self._value

    def _items(self):
        return sorted(self.value.items())

    def str(self):
        return '{%s}' % ', '.join(
            '%s = %s' % (k, v().str()) for k, v in self._items())

    def eq(self, other):
        if type(self) != type(other):
            return Boolean(False)
        else:
            i1 = self._items()
            i2 = other._items()
            return Boolean(len(i1) == len(i2) and
                           all(k1 == k2 and v1().eq(v2()).value
                               for (k1, v1), (k2, v2) in zip(i1, i2)))


class Primitive(StarType):
    def __init__(self, value):
        self._value = value

    @property
    def value(self):
        return self._value

    def str(self):
        return str(self.value)

    def eq(self, other):
        return Boolean(type(self) == type(other) and self.value == other.value)


class Comp(Primitive):
    def le(self, other):
        if type(self) != type(other):
            raise error.StarlingRuntimeError('Type error')
        return Boolean(self.value <= other.value)

class Boolean(Primitive):
    pass


class Number(Comp):
    def add(self, other):
        return Number(self.value + other.value)

    def sub(self, other):
        return Number(self.value - other.value)

    def mul(self, other):
        return Number(self.value * other.value)

    def div(self, other):
        return Number(self.value / other.value)

    def mod(self, other):
        return Number(self.value % other.value)

    def pow(self, other):
        return Number(self.value ** other.value)


class Char(Comp):
    def str(self):
        return repr(self.value)


class Module(Primitive):
    def str(self):
        return 'module'
