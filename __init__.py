import logging
import os

from starling import environment, thunk, glob_env

log = logging.getLogger('starling')

_loc = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))
lib_path = os.path.join(_loc, 'lib.star')

std_lib = ''
with open(lib_path, 'r') as f:
    std_lib = f.read()


def run(script, lib=True):
    log.debug('Running script:\n%s' % script)
    environment.Environment._env_ids = 1

    # wrap script in standard library bindings
    if lib:
        script = '%s\n(\n%s\n)' % (std_lib, script)

    tokens = parse.tokenize(script)
    if len(tokens) == 1:
        return parse.display(thunk.Thunk(tokens[0],
                                         env=glob_env.glob_env).eval())
    else:
        return ""
