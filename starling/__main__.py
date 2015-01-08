from starling import run


def cli():
    # run an interpreter
    while True:
        inp = raw_input('>>> ')
        if inp == 'quit':
            break
        print run(inp)

if __name__ == '__main__':
    cli()
