from starling import parse, error, lib_path
from starling.parse import _parse

from nose.tools import eq_, raises


def _check_parse(s, result=None):
    parse_result = _parse(s)
    print parse_result.dump()
    eq_(parse_result.asList(), result)


@raises(error.StarlingSyntaxError)
def _bad(s):
    _parse(s)


def test_grammar():
    # parser grammar must be valid
    # parse.grammar.validate()

    # parse some really simple scripts
    _check_parse('True', [[['True']]])
    _check_parse('5', [[['5']]])
    _check_parse('x', [[['x']]])
    _check_parse('map', [[['map']]])
    _check_parse('1 + 2', [[['1', '+', '2']]])
    _check_parse('(not True)', [[[['not', 'True']]]])
    _check_parse('6 # still commenting!', [[['6']]])
    _check_parse('foo "My string"', [[['foo', '"My string"']]])
    _check_parse('let f = x -> (x * x) in f 10',
                 [[[[[['f', [['x', [['x', '*', 'x']]]]]], ['f', '10']]]]])

    # obnoxious code
    _check_parse(
        """
        # do the thing!
        (let foo # yeah!
        =          \t   xs
        ->foo
        xs
     in
        (foo [ 1,   # crazy!
        2
        ,3]
    ))
        """,
        [[[[[[['foo', [['xs', ['foo', 'xs']]]]],
             [['foo', [['1'], [['2'], [['3'], ']']]]]]]]]]])

    _bad('(')
    _bad(')')
    _bad('(map f [1 2 3)')
    _bad('(+ 1 2))')
    _bad(')(')
    _bad('let $my_favourite_variable = 0')
    _bad("print 'Bad quote characters!'")

    # attempt to parse standard library
    with open(lib_path, 'r') as f:
        results = _parse(f.read())
    assert len(results)


def _tokenize(s, result):
    eq_(str(parse.tokenize(s)).strip(), result.strip())


def test_tokenize():
    _tokenize('1 + 2',
              'Script:\n'
              '  Expression:\n'
              '    Expression:\n'
              '      Identifier: +\n'
              '      Number: 1\n'
              '    Number: 2')

    _tokenize('let f = x y -> x + y in f 2 10',
              'Script:\n'
              '  Let:\n'
              '    Bindings:\n'
              '      Binding:\n'
              '        Identifier: f\n'
              '        Lambda:\n'
              '          Identifier: x\n'
              '          Lambda:\n'
              '            Identifier: y\n'
              '            Expression:\n'
              '              Expression:\n'
              '                Identifier: +\n'
              '                Identifier: x\n'
              '              Identifier: y\n'
              '    Expression:\n'
              '      Expression:\n'
              '        Identifier: f\n'
              '        Number: 2\n'
              '      Number: 10\n')

    _tokenize('a b c x',
              'Script:\n'
              '  Expression:\n'
              '    Expression:\n'
              '      Expression:\n'
              '        Identifier: a\n'
              '        Identifier: b\n'
              '      Identifier: c\n'
              '    Identifier: x\n')
