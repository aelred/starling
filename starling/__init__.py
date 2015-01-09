import logging
import os

from starling import environment, thunk, glob_env, parse

log = logging.getLogger('starling')

_loc = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))
lib_path = os.path.join(_loc, 'lib.star')


def run(script, lib=True):
    return parse.display(_run(script, lib))


def _run(script, lib=True):
    log.debug('Running script:\n%s' % script)
    environment.Environment._env_ids = 1

    # wrap script in standard library bindings
    if lib:
        env = _std_env
    else:
        env = glob_env.glob_env

    tokens = parse.tokenize(script)
    return thunk.Thunk(tokens, 'script', env).eval()

_std_lib = ''
with open(lib_path, 'r') as f:
    _std_lib = f.read()
_std_env = _run(_std_lib, False)
