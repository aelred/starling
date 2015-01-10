import logging

from starling import star_type

log = logging.getLogger(__name__)


class _EmptyList(star_type.StarType):
    def __iter__(self):
        return iter([])

    def str(self):
        return '[]'

    def eq(self, other):
        return star_type.Boolean(self == other)

empty = _EmptyList()


class List(star_type.StarType):

    def __init__(self, head, tail):
        self._head = head
        self._tail = tail

    def head(self):
        return self._head.eval()

    def tail(self):
        return self._tail.eval()

    def eq(self, other):
        try:
            heads = self.head() == other.head
            tails = self.tail() == other.tail()
            return star_type.Boolean(heads and tails)
        except AttributeError:
            return star_type.Boolean(False)

    def __iter__(self):
        return ListIter(self)

    def str(self):
        return '[%s]' % ', '.join([elem.str() for elem in self])


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
