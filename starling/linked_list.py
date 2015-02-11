import logging

from starling import star_type

log = logging.getLogger(__name__)


class _EmptyList(star_type.StarObject):
    def __iter__(self):
        return iter([])

    def str(self):
        return '[]'

    def eq(self, other):
        return star_type.Boolean(self == other)

    def le(self, other):
        # empty list is the 'first' element when ordered
        return star_type.Boolean(True)

empty = _EmptyList()


class List(star_type.StarObject):

    def __init__(self, head, tail):
        self._head = head
        self._tail = tail

    def head(self):
        return self._head.dethunk()

    def tail(self):
        return self._tail.dethunk()

    def eq(self, other):
        try:
            if not self.head().eq(other.head()).value:
                # don't evaluate tail if heads aren't equal
                return star_type.Boolean(False)
            else:
                return self.tail().eq(other.tail())
        except AttributeError:
            return star_type.Boolean(False)

    def le(self, other):
        try:
            if self.head().eq(other.head()).value:
                return self.tail().le(other.tail())
            else:
                return self.head().le(other.head())
        except AttributeError:
            # if other is empty list, return false
            return star_type.Boolean(False)

    def __iter__(self):
        return ListIter(self)

    def str_generator(self):
        # first check the value of head element
        head = next(iter(self))
        if isinstance(head, star_type.Char):
            # display as a string
            lopen = '"'
            ropen = '"'
            show = lambda elem: [elem.str()[1:-1]]
            delim = False
        else:
            # display as a list
            lopen = '['
            ropen = ']'
            show = lambda elem: elem.str_generator()
            delim = True

        yield lopen
        # generate the results one-by-one
        # infinite lists continuously output!
        prev_elem = None
        for elem in self:
            # this is to make sure there is no comma after last element
            if prev_elem is not None:
                for out in show(prev_elem):
                    yield out
                if delim:
                    yield ', '
            prev_elem = elem
        if prev_elem is not None:
            for out in show(prev_elem):
                yield out
        yield ropen


class ListIter:

    def __init__(self, list_):
        self._list = list_

    def __iter__(self):
        return self

    def next(self):
        list_ = self._list
        try:
            self._list = self._list.tail()
        except AttributeError:
            raise StopIteration()
        return list_.head()
