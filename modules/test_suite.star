let test = import test in
join >> (map str) [
    import test_regex_dot,
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
