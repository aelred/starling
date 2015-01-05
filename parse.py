def tokenize(expr):
    # walk expression, splitting each token
    end_wraps = {
        '(': ')',
        '[': ']',
        '"': '"',
        '#': '\n'
    }
    tokens = []
    token = ''

    def push_token(t):
        # skip comments
        if t and t[0] != '#':
            tokens.append(t.strip())

    wraps = []
    for c in expr:
        if wraps and c == end_wraps[wraps[-1]]:
            wraps.pop()
        elif c in end_wraps.keys():
            wraps.append(c)

        if wraps or not c.isspace():
            token += c
        elif token:
            push_token(token)
            token = ''

    push_token(token)

    if len(tokens) == 1 and _is_wrapper(tokens[0], '(', ')', True):
        # strip parentheses and go again
        tokens = tokenize(strip_wrap(tokens[0], '(', ')'))

    return tuple(tokens)


def strip_wrap(expr, open_char, close_char):
    if expr and expr[0] == open_char and expr[-1] == close_char:
        return expr[1:-1]
    else:
        return expr


def _is_wrapper(expr, open_char, close_char, permit_early_close):
    if len(expr) < 2:
        return False
    else:
        wrapped = expr[0] == open_char and expr[-1] == close_char
        early_close = close_char in expr[1:-1]
        return wrapped and (not early_close or permit_early_close)


def is_identifier(name):
    return isinstance(name, basestring) and name[0] not in '0123456789"(['


def is_string(expr):
    return _is_wrapper(expr, '"', '"', False)


def is_parenthesized(expr):
    return _is_wrapper(expr, '(', ')', True)


def is_list(expr):
    return _is_wrapper(expr, '[', ']', True)


def display(obj):
    try:
        return obj.eval_str()
    except AttributeError:
        if obj is None:
            return ''
        elif isinstance(obj, basestring):
            return '"%s"' % obj
        else:
            return str(obj)
