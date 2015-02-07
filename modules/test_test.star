import test in 
test [
    assert (assert True "Oh dear" = [True, "Pass"]) "Assert failed",
    assert 
        (assert False "That's right" = [False, "That's right"]) 
        "Assert failed",

    assert (test [] = []) "test [] != []",

    assert 
        (test [
            assert (1 = 1) "Bad maths",
            assert (False = False) "Bad logic",
            assert (True = True) "Bad logic",
            assert True "Bad constants"
        ] = []) 
        "Correct tests failed",

    assert 
        (test [assert False "FAILURE"] = [[0, "FAILURE"]]) 
        "Bad test passed",

    assert 
        (test [
            assert (3 = 2) "A", assert (not True) "A"
        ] = [[0, "A"], [1, "A"]]) 
        "Bad tests passed",
    assert 
        (test [
            assert (3*3 = 9) "Pass", assert False "Fail", assert True "Pass"
        ] = [[1, "Fail"]])
        "Bad test passed",
    assert
        (test [
            assert True "Pass", assert True "Pass", assert False "Fail"
        ] = [[2, "Fail"]])
        "Bad test passed"
]
