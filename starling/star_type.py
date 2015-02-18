from starling import error


class StarType(object):
    def str_generator(self):
        """
        Return generator for string output.

        Useful for representing potentially infinite objects.
        Must implement one of str_generator or str.
        """
        yield self.str()

    def str(self):
        """"
        Return string representation for output.

        Must implement one of str_generator or str.
        """
        return ''.join(self.str_generator())

    def repr_generator(self):
        """
        Return string generator for debugging.

        Useful for representing potentially infinite objects.
        Must implement one of repr_generator or repr.
        """
        yield self.repr()

    def repr(self):
        """
        Return string representation for debugging.

        Must implement one of repr_generator or repr.
        """
        return ''.join(self.repr_generator())


class Object(StarType):
    def __init__(self, value):
        self._value = value
        self._items = sorted(self.value.items())

    @property
    def value(self):
        return self._value

    def repr_generator(self):
        if 'head' in self.value and 'tail' in self.value:
            # kind of a hack at the moment
            # treat this like a list
            obj = self
            head = obj.value['head']()
            if isinstance(head, Char):
                # display as a string
                lopen = '"'
                ropen = '"'
                show = lambda elem: [elem.str().encode('string_escape')]
                delim = False
            else:
                # display as a list
                lopen = '['
                ropen = ']'
                show = lambda elem: elem.repr_generator()
                delim = True

            yield lopen
            for s in show(obj.value['head']()):
                yield s
            obj = obj.value['tail']()
            while 'head' in obj.value and 'tail' in obj.value:
                if delim:
                    yield ', '
                for s in show(obj.value['head']()):
                    yield s
                obj = obj.value['tail']()
            yield ropen
        else:
            yield '{'
            if len(self._items) > 0:
                k, v = self._items[0]
                yield k + '='
                for s in v().repr_generator():
                    yield s
                for k, v in self._items[1:]:
                    yield ', ' + k + '='
                    for s in v().repr_generator():
                        yield s
            yield '}'

    def str_generator(self):
        # check if this is a string
        if 'head' in self.value and 'tail' in self.value:
            head = self.value['head']()
            if isinstance(head, Char):
                # return string representation unescaped
                for s in self.repr_generator():
                    sd = s.decode('string_escape')
                    if sd != '"':
                        yield s.decode('string_escape')
                return

        # otherwise, treat as object
        for s in self.repr_generator():
            yield s

    def eq(self, other):
        if type(self) != type(other):
            return Boolean(False)
        else:
            i1 = self._items
            i2 = other._items
            return Boolean(len(i1) == len(i2) and
                           all(k1 == k2 and v1().eq(v2()).value
                               for (k1, v1), (k2, v2) in zip(i1, i2)))


class _EmptyList(Object):
    def __init__(self):
        Object.__init__(self, {})

    def str_generator(self):
        yield '[]'

    def repr_generator(self):
        yield '[]'

    def eq(self, other):
        return Boolean(self == other)

    def le(self, other):
        # empty list is the 'first' element when ordered
        return Boolean(True)

empty_list = _EmptyList()


class Enum(StarType):
    def __init__(self, name, id_):
        self._name = name
        self._id = id_

    def str(self):
        # remove trailing underscore
        return self._name[:-1]

    def repr(self):
        return self.str()

    def eq(self, other):
        return Boolean(type(self) == type(other) and self._id == other._id)


class Primitive(StarType):
    def __init__(self, value):
        self._value = value

    @property
    def value(self):
        return self._value

    def str(self):
        return str(self.value)

    def repr(self):
        return self.str()

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
        return str(self.value)

    def repr(self):
        rep = repr(self.value)
        # replace double quotes with single
        if rep[0] == '"':
            # escape all inner single quotes
            rep = rep.replace('\'', '\\\'')
            rep = '\'' + rep[1:-1] + '\''
        return rep


class Module(Primitive):
    def str(self):
        return 'module'
