from parse import tokenize

from nose.tools import eq_

def test_tokenize():
    eq_(tokenize(''), ())
    eq_(tokenize('1'), ('1',))
    eq_(tokenize('- 2 3'), ('-', '2', '3'))
    eq_(tokenize('"Hello World!"'), ('"Hello World!"',))

