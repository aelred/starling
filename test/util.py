import starling

from nose.tools import eq_, assert_raises, timed
from functools import wraps

def programs(libs):
    def programs_wrapper(f):
        @wraps(f)
        def programs_():
            # we have to go deeper!
            for program, result in f().iteritems():
                yield check_program, program, result, libs
        return programs_
    return programs_wrapper


@timed(2)
def check_program(program, result, lib):
    output = starling.run(program, lib)
    return eq_(output, result, '\n\t%s\nOutput:\n\t%r\nExpected:\n\t%r' % (
        program, output, result))


def errors(f):
    @wraps(f)
    def errors_(err):
        for program in f():
            yield assert_raises, err, starling.run, program
    return errors_
