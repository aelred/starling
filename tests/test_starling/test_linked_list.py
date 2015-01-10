from starling.linked_list import empty
from starling import glob_env, parse

from nose.tools import eq_


def test_empty():
    eq_(str(empty), '[]')
    eq_(list(iter(empty)), [])
    eq_(empty, empty)


def test_list():
    script = '["apple", "banana", "cabbage"]'
    token = parse.tokenize(script)
    li = token.eval(glob_env)
    eq_(li.eval_str(), script)
    # make sure list is not 'consumed' after evaluation
    eq_(li.eval_str(), script)
    eq_(list(iter(li)), ['apple', 'banana', 'cabbage'])
