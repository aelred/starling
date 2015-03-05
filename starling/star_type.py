from starling import error

from itertools import izip_longest


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

    def data_items(self):
        """ Yield only data items, not functions. """
        for k, v in self._items:
            val = v()
            if callable(val):
                continue
            yield k, val

    def repr_generator(self):
        if self.is_list():
            # kind of a hack at the moment
            # treat this like a list
            if self.is_str():
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
            for s in show(self.value['head']()):
                yield s
            obj = self.value['tail']()
            while obj.is_list():
                if delim:
                    yield ', '
                for s in show(obj.value['head']()):
                    yield s
                obj = obj.value['tail']()
            yield ropen
        elif self.is_tuple():
            # treat this as a tuple
            yield '('
            for s in self.value['_0']().repr_generator():
                yield s
            i = 1
            while '_%d' % i in self.value:
                yield ', '
                for s in self.value['_%d' % i]().repr_generator():
                    yield s
                i += 1

            # add trailing comma for one-tuple
            if i == 1:
                yield ','
            yield ')'
        else:
            yield '{'
            items = self.data_items()
            try:
                k, v = next(items)
                yield k + '='
                for s in v.repr_generator():
                    yield s
            except StopIteration:
                pass
            for k, v in items:
                yield ', ' + k + '='
                for s in v.repr_generator():
                    yield s
            yield '}'

    def str_generator(self):
        # check if this is a string
        if self.is_str():
            # return string representation unescaped without surrounding quotes
            gen = self.repr_generator()
            gen.next()
            last = ''
            for s in gen:
                sd = s.decode('string_escape')
                yield last
                last = sd
            return

        # otherwise, treat as object
        for s in self.repr_generator():
            yield s

    def eq(self, other):
        if type(self) != type(other):
            return Boolean(False)
        else:
            i1 = self.data_items()
            i2 = other.data_items()
            zipped = izip_longest(i1, i2, fillvalue=(None, None))
            return Boolean(all(k1 == k2 and v1.eq(v2).value
                               for (k1, v1), (k2, v2) in zipped))

    def le(self, other):
        # everything is greater than the empty list
        if other == empty_list:
            return Boolean(False)

        zipped = izip_longest(
            self.data_items(), other.data_items(), fillvalue=(None, None))

        for (k1, v1), (k2, v2) in zipped:
            # only objects with identical keys are comparable
            if k1 != k2:
                raise error.StarlingRuntimeError(
                    'Type error: Can\'t compare %s and %s' % (
                        self.str(), other.str()))

            if v1.eq(v2).value:
                continue
            elif v1.le(v2).value:
                return Boolean(True)
            else:
                return Boolean(False)

        return Boolean(True)

    def is_tuple(self):
        return '_0' in self.value

    def is_list(self):
        return 'head' in self.value and 'tail' in self.value

    def is_str(self):
        return self.is_list() and isinstance(self.value['head'](), Char)

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

    def le(self, other):
        return Boolean(self._id <= other._id)


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
