from nose.tools import eq_
from cStringIO import StringIO
import sys

from starling import __main__


def _input(inputs, result):
    orig_stdout = sys.stdout

    try:
        out = StringIO()
        sys.stdout = out

        ins = list(inputs)

        def feed_input(prompt):
            return ins.pop(0)

        __main__.raw_input = lambda x: ins.pop(0)
        __main__.cli()

        eq_(out.getvalue().split('\n'), result)
    finally:
        sys.stdout = orig_stdout


def test_input():
    _input(['2 + 1', 'quit'], ['3', ''])
    _input(['quit'], [''])
    _input(['(1, 2)', 'quit'], ['(1, 2)', ''])
    _input(['x=1', 'x+1', 'quit'], ['2', ''])
    _input([' f= x -> x*x', 'x = y', 'x =3 ', 'f x', 'quit'], ['9', ''])
    _input(['x = 3', 'x==3', 'x == 3', 'x== 3', 'x !=3', 'x', 'quit'],
           ['True', 'True', 'True', 'False', '3', ''])
    _input(['enum a b c', 'a', 'b', 'c', 'quit'], ['a', 'b', 'c', ''])
