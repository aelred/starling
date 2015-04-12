from starling import run

import argparse
import logging
import sys
import re


def _print_run(expr=None, source=None, input_=None):
    # print continuous output from script
    for string in run(expr=expr, source=source, generator=True, input_=input_):
        # avoid newlines or spaces between elements
        sys.stdout.write(string)
        sys.stdout.flush()
    # finally print a newline
    print


_re_binding = re.compile(r'^\s*[A-Za-z_][A-Za-z0-9_]*\s*=[^=]')
_re_enum = re.compile(r'^\s*enum\s')


def cli(input_=None):
    # add support for command history
    try:
        import readline
    except:
        pass

    # maintain a list of bindings
    bindings = []

    # run an interpreter
    while True:
        inp = raw_input('>>> ')
        if inp == 'quit':
            break

        if _re_binding.match(inp) or _re_enum.match(inp):
            # if this looks like a binding, store it
            bindings.append(inp)
        else:
            # wrap any existing bindings
            if bindings:
                inp = 'let %s in %s' % (', '.join(bindings), inp)

            try:
                _print_run(expr=inp, input_=input_)
            except Exception, e:
                # print the error, but don't quit
                print e

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Starling interpreter.')
    parser.add_argument('file', nargs='?')
    parser.add_argument('-d', '--debug', action='store_true')
    parser.add_argument('-i', '--input', action='store_true')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)

    if args.input:
        input_ = '\n'.join(sys.stdin.readlines())
    else:
        input_ = None

    if args.file is None:
        cli(input_=input_)
    else:
        _print_run(source=args.file, input_=input_)
