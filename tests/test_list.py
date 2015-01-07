from starling.linked_list import *
from starling import environment, parse

from nose.tools import eq_


def test_empty():
    eq_(str(empty), '[]')
    eq_(list(iter(empty)), [])
    eq_(empty, empty)


def test_list():
    script = '["apple" "banana" "cabbage"]'
    token = parse.tokenize(script)[0].value[0]

    li = List.build(environment.glob_env, token)
    eq_(li.eval_str(), script)
    # make sure list is not 'consumed' after evaluation
    eq_(li.eval_str(), script)
    eq_(list(iter(li)), ['apple', 'banana', 'cabbage'])
