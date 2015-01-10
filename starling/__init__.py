import logging
import os

from starling import environment, glob_env, parse

log = logging.getLogger('starling')

_loc = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))
lib_path = os.path.join(_loc, 'lib.star')

_std_env = None


def run(script, lib=True, generator=False):
    result = _run(script, lib)
    if generator:
        return result.str_generator()
    else:
        return result.str()


def _run(script, lib=True):
    if lib and _std_env is None:
        global _std_env
        std_lib = ''
        with open(lib_path, 'r') as f:
            std_lib = f.read()
        _std_env = _run(std_lib, False).value

    log.debug('Running script:\n%s' % script)
    environment.Environment._env_ids = 1

    # wrap script in standard library bindings
    if lib:
        env = _std_env
    else:
        env = glob_env.glob_env

    tokens = parse.tokenize(script)
    return tokens.eval(env)
