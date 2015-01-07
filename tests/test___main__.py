from nose.tools import eq_
from cStringIO import StringIO
import imp
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
    _input(['+ 2 1', 'quit'], ['3', ''])
    _input(['quit'], [''])
