import logging

from starling import display

log = logging.getLogger(__name__)


class _EmptyList:
    def __iter__(self):
        return iter([])

    def __str__(self):
        return '[]'

empty = _EmptyList()


class List(object):

    def __init__(self, head, tail):
        self._head = head
        self._tail = tail

    def head(self):
        return self._head.eval()

    def tail(self):
        return self._tail.eval()

    def __eq__(self, other):
        try:
            return self.head() == other.head() and self.tail() == other.tail()
        except AttributeError:
            return False

    def __iter__(self):
        return ListIter(self)

    def eval_str(self):
        # this isn't __str__ or __repr__ so we don't accidentally eval
        # an entire (potentially infinite) list.
        return '[%s]' % ' '.join([display.display(elem) for elem in self])


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
