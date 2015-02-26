let test = import test in
test.report True >> join [
    import test_dict,
    import test_starparse,
    import test_parser,
    import test_starlex,
    import test_test,
    import test_lang,
    import test_lib,
    import test_euler,
    import test_set,
    import test_regex,
    import test_lexer
]
