import starling

import re
from nose.tools import eq_, ok_, assert_raises
from functools import wraps


def programs(libs, from_file=False, has_input=False, re_match=False):
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
                    expr = None
                    source = program
                else:
                    expr = program
                    source = None
                yield (
                    check_program, expr, source, input_, result, libs, re_match
                )
        return programs_
    return programs_wrapper


def check_program(expr, source, input_, result, lib, re_match):
    output = starling.run(expr, source, input_=input_, lib=lib)
    msg = '\n\t%s\n%s\nOutput:\n\t%r\nExpected:\n\t%r' % (
        expr, source, output, result)
    if not re_match:
        return eq_(output, result, msg)
    else:
        return ok_(re.match(result, output), msg)


def errors(err):
    def error_wrapper(f):
        @wraps(f)
        def errors_():
            for program in f():
                yield assert_raises, err, starling.run, program
        return errors_
    return error_wrapper
