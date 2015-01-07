from linked_list import empty, List
from environment import glob_env
from parse import tokenize

from nose.tools import eq_


def test_empty():
    eq_(str(empty), '[]')
    eq_(list(iter(empty)), [])
    eq_(empty, empty)


def test_list():
    script = '["apple" "banana" "cabbage"]'
    token = tokenize(script)[0].value[0]

    li = List.build(glob_env, token)
    eq_(li.eval_str(), script)
    # make sure list is not 'consumed' after evaluation
    eq_(li.eval_str(), script)
    eq_(list(iter(li)), ['apple', 'banana', 'cabbage'])
