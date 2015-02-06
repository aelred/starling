import test in 
test [
    [assert True "Oh dear" = [True, "Pass"], "Assert failed"],
    [assert False "That's right" = [False, "That's right"], "Assert failed"],

    [test [] = [], "test [] != []"],

    [test [
        [1 = 1, "Bad maths"],
        [False = False, "Bad logic"],
        [True = True, "Bad logic"],
        [True, "Bad constants"]
    ] = [], "Correct tests failed"],

    [test [[False, "FAILURE"]] = [[0, "FAILURE"]], "Bad test passed"],

    [test [
        [3 = 2, "A"], [not True, "A"]
    ] = [[0, "A"], [1, "A"]], "Bad tests passed"],
    [test [
        [3*3 = 9, "Pass"], [False, "Fail"], [True, "Pass"]
    ] = [[1, "Fail"]], "Bad test passed"],
    [test [
        [True, "Pass"], [True, "Pass"], [False, "Fail"]
    ] = [[2, "Fail"]], "Bad test passed"]
]
