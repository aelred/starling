import starling

from nose.tools import eq_, assert_raises
from functools import wraps


def programs(libs, from_file=False):
    def programs_wrapper(f):
        @wraps(f)
        def programs_():
            # we have to go deeper!
            for program, result in f().iteritems():
                if from_file:
                    with open(program, 'r') as script:
                        program = script.read()
                yield check_program, program, result, libs
        return programs_
    return programs_wrapper


def check_program(program, result, lib):
    output = starling.run(program, lib)
    return eq_(output, result, '\n\t%s\nOutput:\n\t%r\nExpected:\n\t%r' % (
        program, output, result))


def errors(err):
    def error_wrapper(f):
        @wraps(f)
        def errors_():
            for program in f():
                yield assert_raises, err, starling.run, program
        return errors_
    return error_wrapper
