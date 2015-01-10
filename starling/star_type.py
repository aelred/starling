class StarType(object):
    pass


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


class Boolean(Primitive):
    pass


class Number(Primitive):
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

    def gt(self, other):
        return Boolean(self.value > other.value)

    def lt(self, other):
        return Boolean(self.value < other.value)


class String(Primitive):
    def str(self):
        return '"%s"' % self.value


class Module(Primitive):
    def str(self):
        return 'module'
