import logging
import os
import sys

from starling import parse, star_path

log = logging.getLogger('starling')

lib_path = os.path.join(star_path.path, 'lib.star')

_std_binds = None

sys.setrecursionlimit(20000)


def run(expr=None, source=None, input_=None, lib=True, generator=False):
    result = run_raw(expr, source, input_, lib)
    gen = result.str_generator()
    if generator:
        return gen
    else:
        return ''.join(gen)


def run_raw(expr, source, input_=None, lib=True):
    if expr is not None:
        return parse.evaluate_expr(expr, lib=lib, input_=input_)
    else:
        return parse.evaluate_star(source, lib=lib, input_=input_)
