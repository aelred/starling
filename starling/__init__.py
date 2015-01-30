import logging
import os
import sys

from starling import environment, glob_env, parse, star_path

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
    if lib and _std_binds is None:
        global _std_binds
        std_lib = ''
        with open(lib_path, 'r') as f:
            std_lib = f.read()
        _std_binds = run_raw(std_lib, lib=False).value

    log.debug('Running script:\n%s' % script)
    environment.Environment._env_ids = 1

    # wrap script in standard library bindings
    if lib:
        env = glob_env.glob_env.child(_std_binds, 'global')
    else:
        env = glob_env.glob_env

    # input environment
    env = env.child({'input': glob_env.const_string(input_)})

    tokens = parse.tokenize(script)
    return tokens.eval(env)
