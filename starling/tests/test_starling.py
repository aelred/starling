from starling import error
from util import programs, errors

from nose import with_setup
import sys

rec_limit = sys.getrecursionlimit()


def setup_low_rec():
    sys.setrecursionlimit(300)


def teardown_low_rec():
    sys.setrecursionlimit(rec_limit)


@with_setup(setup_low_rec, teardown_low_rec)
@programs(False)
def test_lazy():
    # (let f=f in f) means 'define a function f that calls f, then call f.
    # recurses forever. If it ever evaluates, the script will not terminate
    return {
        'if False then let f=f in f else "good"': '"good"',
        'head ["fine", (let f=f in f)]': '"fine"',
        '[0, let f=f in f] = [10, let f=f in f]': 'False',
        'strict 4 : [2]': '[4, 2]',
        """
        let r = \\n:
            strict if n = 0 then [] else r strict (n - 1) in r 1000
        """: '[]'
    }


@programs(False, has_input=True)
def test_input():
    return {
        ('head input', 'Boo'): "'B'",
        ('tail input', 'Boo'): '"oo"'
    }


@programs(False)
def test_export():
    return {
        'let foo = 3 in export foo': 'module'
    }


@errors(error.StarlingSyntaxError)
def test_syntax_error():
    return [
        '(3 * 2'
    ]


@errors(error.StarlingRuntimeError)
def test_runtime_error():
    return [
        '(1 == 2)',
        'a',
        '((let y=10 in y) + y)',
        '(let foo=(\ x: 2 * x) in (foo x))',
        'if 1 then 2 else 0',
        '3 <= "False"'
    ]
