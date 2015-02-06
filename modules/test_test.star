import test in 
test [
    test [] = [],
    test [
        1 = 1,
        False = False,
        True = True,
        True
    ] = [],
    test [False] = [0],
    test [3 = 2, not True] = [0, 1],
    test [3*3 = 9, False, True] = [1],
    test [True, True, False] = [2]
]
