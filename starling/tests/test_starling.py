import starling
from starling import error

from nose import with_setup
from nose.tools import eq_, assert_raises
import sys
from functools import wraps


def programs(has_input=False):
    def programs_wrapper(f):
        @wraps(f)
        def programs_():
            # we have to go deeper!
            for program, result in f().iteritems():
                if has_input:
                    program, input_ = program
                else:
                    input_ = ""
                expr = program
                yield (
                    check_program, expr, input_, result
                )
        return programs_
    return programs_wrapper


def check_program(expr, input_, result):
    output = starling.run(expr, None, input_=input_)
    msg = '\n\t%s\nOutput:\n\t%r\nExpected:\n\t%r' % (expr, output, result)
    return eq_(output, result, msg)


def errors(err):
    def error_wrapper(f):
        @wraps(f)
        def errors_():
            for program in f():
                yield assert_raises, err, starling.run, program
        return errors_
    return error_wrapper

rec_limit = sys.getrecursionlimit()


def setup_low_rec():
    sys.setrecursionlimit(300)


def teardown_low_rec():
    sys.setrecursionlimit(rec_limit)


@with_setup(setup_low_rec, teardown_low_rec)
@programs()
def test_lazy():
    # (let f=f in f) means 'define a function f that calls f, then call f.
    # recurses forever. If it ever evaluates, the script will not terminate
    return {
        'if False then let f=f in f else "good"': 'good',
        '["fine", (let f=f in f)].head': 'fine',
        '[0, let f=f in f] = [10, let f=f in f]': 'False',
        'strict 4 : [2]': '[4, 2]',
        """
        let r = \\n:
            strict if n = 0 then [] else r strict (n - 1) in r 1000
        """: '[]'
    }


@programs(has_input=True)
def test_input():
    return {
        ('input.head', 'Boo'): 'B',
        ('input.tail', 'Boo'): 'oo'
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
