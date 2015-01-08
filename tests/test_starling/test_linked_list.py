from starling.linked_list import empty
from starling import glob_env, parse, thunk

from nose.tools import eq_


def test_empty():
    eq_(str(empty), '[]')
    eq_(list(iter(empty)), [])
    eq_(empty, empty)


def test_list():
    script = '["apple" "banana" "cabbage"]'
    token = parse.tokenize(script)
    li = thunk.Thunk(token, 'list', glob_env).eval()
    eq_(li.eval_str(), script)
    # make sure list is not 'consumed' after evaluation
    eq_(li.eval_str(), script)
    eq_(list(iter(li)), ['apple', 'banana', 'cabbage'])
