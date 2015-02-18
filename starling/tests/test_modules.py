from util import programs

passes = r"\[({pass=True}(, )?)*\]$"


@programs(True, True, re_match=True)
def test_modules():
    return {
        'test_lang': passes,
        'test_regex': passes,
        'test_test': passes,
        'test_lib': passes,
        'test_set': passes,
        'test_lexer': passes,
        'euler1': '233168',
        'euler2': '4613732'
    }
