import starling
from starling import star_path

from nose.tools import eq_, assert_raises
from functools import wraps
import os


def programs(libs, from_file=False, has_input=False):
    def programs_wrapper(f):
        @wraps(f)
        def programs_():
            # we have to go deeper!
            for program, result in f().iteritems():
                if has_input:
                    program, input_ = program
                else:
                    input_ = ""
                if from_file:
                    path = os.path.join(star_path.path, program + '.star')
                    with open(path, 'r') as script:
                        program = script.read()
                yield check_program, program, input_, result, libs
        return programs_
    return programs_wrapper


def check_program(program, input_, result, lib):
    output = starling.run(program, input_=input_, lib=lib)
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
