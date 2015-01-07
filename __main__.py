import environment
import parse

from function import Thunk

if __name__ == '__main__':
    # run an interpreter
    while True:
        print run(raw_input('>>> '))
