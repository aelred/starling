from util import programs


@programs(True, True)
def test_modules():
    return {
        'euler2': '4613732',
        'test_regex': '[]',
        'test_test': '[]',
        'test_lib': '[]'
    }
