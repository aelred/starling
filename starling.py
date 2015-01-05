import logging

import environment
import parse

log = logging.getLogger('starling')

std_lib = ''
with open('lib.star', 'r') as f:
    std_lib = f.read()


def run(script, lib=True):
    log.debug('Running script:\n%s' % script)
    environment.Environment._env_ids = 1

    # wrap script in standard library bindings
    if lib:
        script = '%s\n(\n%s\n)' % (std_lib, script)

    return parse.display(environment.glob_env.eval(script))

if __name__ == '__main__':
    # run an interpreter
    while True:
        print run(raw_input('>>> '))
