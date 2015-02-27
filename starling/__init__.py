import logging
import os
import sys
from itertools import ifilter

from starling import parse, star_path

log = logging.getLogger('starling')

lib_path = os.path.join(star_path.path, 'lib.star')

_std_binds = None

sys.setrecursionlimit(20000)


def _str_gen(result):
    """ Don't yield surrounding '"' in strings """
    g = result.str_generator()
    c = next(g)
    if c == '"':
        is_str = True
        last = ''
    else:
        is_str = False
        last = '"'

    try:
        for c in g:
            yield last
            last = c
    except StopIteration:
        if not is_str:
            yield last


def run(expr=None, source=None, input_=None, lib=True, generator=False):
    result = run_raw(expr, source, input_, lib)
    if generator:
        return _str_gen(result)
    else:
        return result.str()


def run_raw(expr, source, input_=None, lib=True):
    if expr is not None:
        return parse.evaluate_expr(expr, lib=lib, input_=input_)
    else:
        return parse.evaluate_star(source, lib=lib, input_=input_)
