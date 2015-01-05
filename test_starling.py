import starling
import error
from parse import tokenize

from nose.tools import eq_, assert_raises, timed
from functools import wraps


def programs(libs):
    def programs_wrapper(f):
        @wraps(f)
        def programs_():
            # we have to go deeper!
            for program, result in f().iteritems():
                yield check_program, program, result, libs
        return programs_
    return programs_wrapper


@timed(2)
def check_program(program, result, lib):
    output = starling.run(program, lib)
    return eq_(output, result, '\n\t%s\nOutput:\n\t%r\nExpected:\n\t%r' % (
        program, output, result))


def errors(f):
    @wraps(f)
    def errors_(err):
        for program in f():
            yield assert_raises, err, starling.run, program
    return errors_


def test_tokenize():
    eq_(tokenize(''), ())
    eq_(tokenize('1'), ('1',))
    eq_(tokenize('- 2 3'), ('-', '2', '3'))
    eq_(tokenize('"Hello World!"'), ('"Hello World!"',))


@programs(False)
def test_run():
    return {'': ''}


@programs(False)
def test_string():
    return {'"Hello World!"': '"Hello World!"'}


@programs(False)
def test_math():
    return {
        '14': '14',
        '+ 14 3': '17',
        '- 12 3': '9',
        '* 1 2': '2',
        '/ 6 2': '3',
        '(+ 3 2)': '5',
        '(+ 10 (* 3 3))': '19',
        'mod 10 2': '0',
        'mod 9 2': '1',
        'mod 6 6': '0',
        'mod 5 3': '2'
    }


@programs(False)
def test_logic():
    return {
        '= 3 0': 'False',
        '= 0 0': 'True',
        '< 2 0': 'False',
        '< 0 2': 'True',
        '< 0 0': 'False',
        '> 2 0': 'True',
        '> 0 2': 'False',
        '> 0 0': 'False',
        'False': 'False',
        'True': 'True',
    }


@programs(False)
def test_if():
    return {'if (> 1 2) "Oh dear..." "Great!"': '"Great!"'}


@programs(False)
def test_const():
    return {
        'let a 5 (+ a 1)': '6',
        'let x 2 (/ (let x 10 x) x)': '5',
    }


@programs(False)
def test_func():
    return {
        'let square (\ x (* x x)) (square 5)': '25',
        'let avg (\ x (\ y (/ (+ x y) 2))) (let a 6 (avg a 8))': '7'
    }


@programs(False)
def test_list():
    return {
        '[]': '[]',
        '[1]': '[1]',
        '[1 2]': '[1 2]',
        'head [1 2 3]': '1',
        'tail [1 2 3]': '[2 3]',
        'cons 1 []': '[1]',
        'cons 2 [10]': '[2 10]',
        'cons 3 (cons 2 (cons 1 []))': '[3 2 1]',
    }


@programs(False)
def test_recursion():
    return {
        """
        let tri (\ x (if (= x 0) 0 (+ (tri (- x 1)) x)))
        (tri 4)
        """: '10',

        """
        let fib
        (
            \ x
            (
                if (= x 0)
                0
                (
                    if (= x 1)
                    1
                    (+ (fib (- x 1)) (fib (- x 2)))
                )
            )
        )
        (fib 6)
        """: '8',
    }


@programs(False)
def test_lazy():
    # (let f f f) means 'define a function f that calls f, then call f.
    # recurses forever. If it ever evaluates, the script will not terminate
    return {
        'if False (let f f f) "good"': '"good"',
        'head ["fine" (let f f f)]': '"fine"'
    }


@programs(False)
def test_comment():
    return {
        '# this is a comment': '',
        '#so is this': '',
        '#\t and this!': '',
        '5 # return 5': '5',

        """
        # inverts a number
        let inv
        (
            \ x  # accepts one argument, x
            (    # and then... (this is my favourite bit)
                - 0 x  # return 0 - x = -x
            )
        )
        inv 10  # call with arg 10, should return -10
        """: '-10'
    }


@programs(True)
def test_partial():
    return {
        '(+ 3) 5': '8',
        'map (* 2) [1 2 3]': '[2 4 6]',
        'filter (= "a") ["a" "b" "a" "a"]': '["a" "a" "a"]'
    }


@errors(error.StarlingSyntaxError)
def test_syntax_error():
    return [
        '(1 == 2)',
        '(3 * 2'
    ]


@errors(error.StarlingRuntimeError)
def test_runtime_error():
    return [
        'a',
        '(+ (let y 10 y) y)',
        '(let foo (\ x (* 2 x)) (foo x))'
    ]
