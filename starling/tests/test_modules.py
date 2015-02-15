from util import programs


@programs(True, True)
def test_modules():
    return {
        'test_lang': '[]',
        'euler1': '233168',
        'euler2': '4613732',
        'test_regex': '[]',
        'test_test': '[]',
        'test_lib': '[]',
        'test_set': '[]'
    }
