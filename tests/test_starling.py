from starling import error

from util import programs, errors


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
        'mod 5 3': '2',
        'pow 5 0': '1',
        'pow 60 1': '60',
        'pow 5 2': '25',
        'pow 2 8': '256'
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
    return {'if > 1 2 then "Oh dear..." else "Great!"': '"Great!"'}


@programs(False)
def test_const():
    return {
        'let a=5 in + a 1': '6',
        'let x=2 in (/ (let x=10 in x) x)': '5',
    }


@programs(False)
def test_func():
    return {
        'let square=\\x: * x x in (square 5)': '25',
        'let avg = (\ x y: (/ (+ x y) 2)) in (let a= 6 in (avg a 8))': '7'
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
        let tri = \ x: (if = x 0 then 0 else + (tri (- x 1)) x) in
        (tri 4)
        """: '10',

        """
        let fib = \ x:
            if = x 0
            then 0
            else if = x 1
            then 1
            else + (fib (- x 1)) (fib (- x 2))
        in fib 6
        """: '8',
    }


@programs(False)
def test_lazy():
    # (let f=f in f) means 'define a function f that calls f, then call f.
    # recurses forever. If it ever evaluates, the script will not terminate
    return {
        'if False then let f=f in f else "good"': '"good"',
        'head ["fine" (let f=f in f)]': '"fine"'
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
        let inv =
        (
            \ x:  # accepts one argument, x
            (    # and then... (this is my favourite bit)
                - 0 x  # return 0 - x = -x
            )
        ) in
        inv 10  # call with arg 10, should return -10
        """: '-10'
    }


@programs(False)
def test_partial():
    return {
        '(+ 3) 5': '8'
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
        '(+ (let y=10 in y) y)',
        '(let foo=(\ x: * 2 x) in (foo x))'
    ]
