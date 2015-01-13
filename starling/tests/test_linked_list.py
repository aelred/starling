from starling.linked_list import empty
from starling import glob_env, parse

from nose.tools import eq_


def test_empty():
    eq_(empty.str(), '[]')
    eq_(list(iter(empty)), [])
    eq_(empty, empty)


def test_list():
    script = '["apple", "banana", "cabbage"]'
    token = parse.tokenize(script)
    li = token.eval(glob_env)
    # test list equals itself
    assert li.eq(parse.tokenize(script).eval(glob_env)).value
    eq_(li.str(), script)
    # make sure list is not 'consumed' after evaluation
    eq_(li.str(), script)
    eq_([s.str() for s in li], ['"apple"', '"banana"', '"cabbage"'])
