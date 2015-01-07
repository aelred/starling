import parse
from parse import Token

from nose.tools import eq_, raises
import pyparsing


def _parse(s, result=None):
    parse_result = parse.grammar.parseString(s)
    print parse_result.dump()
    eq_(parse_result.asList(), result)

@raises(pyparsing.ParseSyntaxException, pyparsing.ParseException)
def _bad(s):
    parse.grammar.parseString(s)


def test_grammar():
    # parser grammar must be valid
    parse.grammar.validate()

    # parse some really simple scripts
    # _parse('', [])
    _parse('True', [['True']])
    _parse('5', [['5']])
    _parse('x', [['x']])
    _parse('map', [['map']])
    _parse('+ 1 2', [['+', '1', '2']])
    _parse('(not True)', [[['not', 'True']]])
    _parse('# commenting!', [])
    _parse('6 # still commenting!', [['6']])
    _parse('foo "My string"', [['foo', '"My string"']])
    _parse('(let f (\ x (x * x)) (f 10))',
        [[['let', 'f',
          [
           '\\', 'x',
           ['x', '*', 'x'],
          ],
          ['f', '10'],
         ]]
        ])

    # obnoxious code
    _parse(
        """
            # do the thing!
            (let foo # yeah!
                    (     \\    \t   xs
            (foo
            xs  )
        )
            foo [ 1   # crazy!
            2
        3]
        )
        """,
        [[[
           'let', 'foo',
           [
            '\\', 'xs', ['foo', 'xs'],
           ],
           'foo', ['1', '2', '3'],
          ]
        ]])

    _bad('(')
    _bad(')')
    _bad('(map f [1 2 3)')
    _bad('(+ 1 2))')
    _bad(')(')
    _bad('let $my_favourite_variable 0')

    # attempt to parse standard library
    results = parse.grammar.parseFile('lib.star')
    assert len(results)


def _tokenize(s, result):
    eq_(parse.tokenize(s), result)


def test_tokenize():
    _tokenize('+ 1 2',
              [Token(['expression'],
                [Token(['identifier', 'atom'], '+'),
                 Token(['number', 'atom'], '1'),
                 Token(['number', 'atom'], '2')])])
