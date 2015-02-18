from starling import run

import argparse
import logging
import sys


def _print_run(expr=None, source=None):
    # print continuous output from script
    for string in run(expr=expr, source=source, generator=True):
        # avoid newlines or spaces between elements
        sys.stdout.write(string)
        sys.stdout.flush()
    # finally print a newline
    print


def cli():
    # run an interpreter
    while True:
        inp = raw_input('>>> ')
        if inp == 'quit':
            break
        _print_run(expr=inp)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Starling interpreter.')
    parser.add_argument('file', nargs='?')
    parser.add_argument('-d', '--debug', action='store_true')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)

    if args.file is None:
        cli()
    else:
        _print_run(source=args.file)
