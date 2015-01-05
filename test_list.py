from linked_list import empty, List
from environment import glob_env

from nose.tools import eq_


def test_empty():
    eq_(str(empty), '[]')
    eq_(list(iter(empty)), [])
    eq_(empty, empty)


def test_list():
    li = List.build(glob_env, '["apple" "banana" "cabbage"]')
    eq_(li.eval_str(), '["apple" "banana" "cabbage"]')
    eq_(list(iter(li)), ['apple', 'banana', 'cabbage'])
