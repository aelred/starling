from starling.linked_list import empty
from starling import parse

from nose.tools import eq_


def test_empty():
    eq_(empty.str(), '[]')
    eq_(list(iter(empty)), [])
    eq_(empty, empty)


def test_list():
    script = '["apple", "banana", "cabbage"]'
    li = parse.evaluate_expr(script)
    # test list equals itself
    assert li.eq(parse.evaluate_expr(script)).value
    eq_(li.str(), script)
    # make sure list is not 'consumed' after evaluation
    eq_(li.str(), script)
    eq_([s.str() for s in li], ['"apple"', '"banana"', '"cabbage"'])
