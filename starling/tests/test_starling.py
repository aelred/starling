from starling import error

from util import programs, errors


@programs(False)
def test_char():
    return {
        '\'a\'': '\'a\'',
        '"Hello World!"': '"Hello World!"',
        'head "Hi"': '\'H\'',
        'tail "Hi"': '"i"',
        'tail "a"': '[]',
        '\'H\' : (\'i\' : [])': '"Hi"'
    }


@programs(False)
def test_math():
    return {
        '14': '14',
        '14 + 3': '17',
        '12 - 3': '9',
        '1 * 2': '2',
        '6 / 2': '3',
        '(3 + 2)': '5',
        '(10 + (3 * 3))': '19',
        '10 mod 2': '0',
        '9 mod 2': '1',
        '6 mod 6': '0',
        '5 mod 3': '2',
        '5 pow 0': '1',
        '60 pow 1': '60',
        '5 pow 2': '25',
        '2 pow 8': '256'
    }


@programs(False)
def test_infix():
    return {
        '2 + 3': '5',
        '1 + 2 + 3': '6',
        '5 - 1 - 2': '2',
        '(+ 2) 3': '5',
        '(2 +) 3': '5',
        '(/ 2) 10': '5',
        '(10 /) 2': '5'
    }


@programs(False)
def test_logic():
    return {
        '3 = 0': 'False',
        '0 = 0': 'True',
        '4 <= 6': 'True',
        '6 <= 6': 'True',
        '6 <= 4': 'False',
        'False': 'False',
        'True': 'True',
    }


@programs(False)
def test_if():
    return {'if 2 <= 1 then "Oh dear..." else "Great!"': '"Great!"'}


@programs(False)
def test_const():
    return {
        'let a=5 in a + 1': '6',
        'let x=2 in ((let x=10 in x) / x)': '5',
    }


@programs(False)
def test_func():
    return {
        'let square=\\x: x * x in (square 5)': '25',
        'let avg = (\ x y: ((x + y) / 2)) in (let a= 6 in (avg a 8))': '7'
    }


@programs(False)
def test_list():
    return {
        '[]': '[]',
        '[1]': '[1]',
        '[1, 2]': '[1, 2]',
        'head [1, 2, 3]': '1',
        'tail [1, 2, 3]': '[2, 3]',
        '1 : []': '[1]',
        '2 : [10]': '[2, 10]',
        '3 : (2 : (1 : []))': '[3, 2, 1]',
    }


@programs(False)
def test_recursion():
    return {
        """
        let tri = \ x: (if x = 0 then 0 else (tri (x - 1)) + x) in
        (tri 4)
        """: '10',

        """
        let fib = \ x:
            if x = 0
            then 0
            else if x = 1
            then 1
            else fib (x - 1) + (fib (x - 2))
        in fib 6
        """: '8',
    }


@programs(False)
def test_lazy():
    # (let f=f in f) means 'define a function f that calls f, then call f.
    # recurses forever. If it ever evaluates, the script will not terminate
    return {
        'if False then let f=f in f else "good"': '"good"',
        'head ["fine", (let f=f in f)]': '"fine"'
    }


@programs(False)
def test_comment():
    return {
        '1 # this is a comment': '1',
        '"hi" #so is this': '"hi"',
        '"# not this" #\t and this!': '"# not this"',
        '5 # return 5': '5',

        """
        # inverts a number
        let inv =
        (
            \ x:  # accepts one argument, x
            (    # and then... (this is my favourite bit)
                0 - x  # return 0 - x = -x
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


@programs(False)
def test_import():
    return {
        'import test_module in test_message': '"Import successful!"'
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
