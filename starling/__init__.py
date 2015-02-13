import logging
import os
import sys

from starling import parse, star_path

log = logging.getLogger('starling')

lib_path = os.path.join(star_path.path, 'lib.star')

_std_binds = None

sys.setrecursionlimit(10000)


def run(script, input_='', lib=True, generator=False):
    result = run_raw(script, input_, lib)
    if generator:
        return result.str_generator()
    else:
        return result.str()


def run_raw(script, input_='', lib=True):
    tokens = parse.tokenize('let input="%s" in\n%s' % (input_, script))

    # wrap script in standard library bindings
    if lib:
        with open(lib_path, 'r') as f:
            std_lib = f.read()
        tokens = tokens.wrap_import(parse.tokenize(std_lib))

    return tokens.evaluate()
