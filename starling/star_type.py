from starling import error
from starling.util import trampoline, Thunk

from itertools import izip, izip_longest


# these are set by the standard starling library later
cons = None
empty_list = None


def _str_to_list(s):
    try:
        c = next(s)
        head = Thunk(lambda: Char(c))
        tail = Thunk(lambda: _str_to_list(s))
        return cons()(head)(tail)
    except StopIteration:
        return empty_list


class Object(object):
    def __init__(self, items):
        # store a copy of items without any defaults
        self.items_no_defaults = dict(items)
        self._items = items

        # give default str and repr functions
        if 'str' not in items or self.is_str():
            self._def_str = True
            items['str'] = lambda: lambda o: _str_to_list(o()._str_default())
        else:
            self._def_str = False

        if 'repr' not in items or self.is_str():
            self._def_repr = True
            items['repr'] = lambda: lambda o: _str_to_list(o()._repr_default())
        else:
            self._def_repr = False

    @property
    def items(self):
        return self._items

    def data_items(self):
        """ Yield only data items, not functions. """
        for k, v in sorted(self._items.items()):
            val = v()
            if callable(val):
                continue
            yield k, val

    def _repr_default(self):
        if self.is_str():
            # display as a string
            obj = self
            yield '"'
            while obj.is_list():
                for s in obj.items['head']().str().encode('string_escape'):
                    yield s
                obj = obj.items['tail']()
            yield '"'
        elif self.is_tuple():
            # treat this as a tuple
            yield '('
            for s in self.items['_0']().repr_generator():
                yield s
            i = 1
            while '_%d' % i in self.items:
                yield ', '
                for s in self.items['_%d' % i]().repr_generator():
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
                for s in k:
                    yield s
                yield '='
                for s in v.repr_generator():
                    yield s
            except StopIteration:
                pass
            for k, v in items:
                yield ','
                yield ' '
                for s in k:
                    yield s
                yield '='
                for s in v.repr_generator():
                    yield s
            yield '}'

    def repr(self):
        return ''.join(self.repr_generator())

    def repr_generator(self):
        if self._def_repr:
            for s in self._repr_default():
                yield s
        else:
            for s in trampoline(self.items['repr']()(self)).str_generator():
                yield s

    def _str_default(self):
        if self.is_str():
            # return string unescaped without surrounding quotes
            obj = self
            while obj.is_list():
                for s in obj.items['head']().str():
                    yield s
                obj = obj.items['tail']()
            return
        else:
            for s in self.repr_generator():
                yield s

    def str(self):
        return ''.join(self.str_generator())

    def str_generator(self):
        if self._def_str:
            for s in self._str_default():
                yield s
        else:
            for s in trampoline(self.items['str']()(self)).str_generator():
                yield s

    def eq(self, other):
        if type(self) != type(other):
            print "NOOPPPE"
            return Boolean(False)
        else:
            i1 = self.data_items()
            i2 = other.data_items()
            zipped = izip_longest(i1, i2, fillvalue=(None, None))
            return Boolean(all(k1 == k2 and v1.eq(v2).value
                           for (k1, v1), (k2, v2) in zipped))

    def le(self, other):
        zipped = izip(self.data_items(), other.data_items())

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

        # everything is greater than the empty object
        if (len(list(self.data_items())) > 0 and
           len(list(other.data_items())) == 0):
            return Boolean(False)
        else:
            return Boolean(True)

    def is_tuple(self):
        return '_0' in self.items

    def is_list(self):
        return 'head' in self.items and 'tail' in self.items

    def is_str(self):
        return self.is_list() and isinstance(self.items['head'](), Char)


class Enum(Object):
    def __init__(self, name, id_):
        Object.__init__(self, {})
        self._name = name
        self._id = id_

    def _str_default(self):
        # remove trailing underscore
        return iter(self._name[:-1])

    def _repr_default(self):
        return iter(self._str_default())

    def eq(self, other):
        return Boolean(type(self) == type(other) and self._id == other._id)

    def le(self, other):
        return Boolean(self._id <= other._id)


class Primitive(Object):
    def __init__(self, value):
        Object.__init__(self, {})
        self._value = value

    @property
    def value(self):
        return self._value

    def _str_default(self):
        return iter(str(self.value))

    def _repr_default(self):
        return iter(self._str_default())

    def eq(self, other):
        return Boolean(type(self) == type(other) and self.value == other.value)


class Comp(Primitive):
    def le(self, other):
        if type(self) != type(other):
            raise error.StarlingRuntimeError('Type error')
        return Boolean(self.value <= other.value)


class Boolean(Primitive):
    pass

True_ = Boolean(True)

False_ = Boolean(False)


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
    def _str_default(self):
        yield str(self.value)

    def _repr_default(self):
        rep = repr(self.value)
        # replace double quotes with single
        if rep[0] == '"':
            # escape all inner single quotes
            rep = rep.replace('\'', '\\\'')
            rep = '\'' + rep[1:-1] + '\''
        for s in rep:
            yield s
