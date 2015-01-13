import logging
import os

from starling import environment, glob_env, parse, star_path

log = logging.getLogger('starling')

lib_path = os.path.join(star_path.path, 'lib.star')

_std_env = None


def run(script, input_='', lib=True, generator=False):
    result = _run(script, input_, lib)
    if generator:
        return result.str_generator()
    else:
        return result.str()


def _run(script, input_='', lib=True):
    if lib and _std_env is None:
        global _std_env
        std_lib = ''
        with open(lib_path, 'r') as f:
            std_lib = f.read()
        _std_env = _run(std_lib, lib=False).value

    log.debug('Running script:\n%s' % script)
    environment.Environment._env_ids = 1

    # wrap script in standard library bindings
    if lib:
        env = _std_env
    else:
        env = glob_env.glob_env

    # input environment
    env = env.child({'input': glob_env.const_string(input_)})

    tokens = parse.tokenize(script)
    return tokens.eval(env)
