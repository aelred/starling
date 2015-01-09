from starling import run

import argparse
import logging


def cli():
    # run an interpreter
    while True:
        inp = raw_input('>>> ')
        if inp == 'quit':
            break
        print run(inp)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Starling interpreter.')
    parser.add_argument('-d', '--debug', action='store_true')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)

    cli()
