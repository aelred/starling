let test = import test in
test.report >> join [
    import test_test,
    import test_lang,
    import test_lib,
    import test_euler,
    import test_set,
    import test_regex,
    import test_lexer
]
