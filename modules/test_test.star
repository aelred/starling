import test in 
test [
    assert_equal (assert True "Oh dear") [True, "Pass"],
    assert_equal (assert False "That's right") [False, "That's right"],

    assert_equal (assert_equal 3 3) [True, "Pass"],
    assert_equal (assert_equal 3 (10 - 6)) [False, ["unequal", 3, 4]],

    assert_equal (test []) [],

    assert_equal
        (test [
            assert_equal 1 1,
            assert_equal False False,
            assert_equal True True,
            assert True "Bad constants"
        ]) [],

    assert_equal (test [assert False "FAILURE"]) [[0, "FAILURE"]],

    assert_equal
        (test [
            assert_equal 3 2, assert (not True) "A"
        ]) [[0, ["unequal", 3, 2]], [1, "A"]],
    assert_equal
        (test [
            assert (3*3 = 9) "Pass", assert False "Fail", assert True "Pass"
        ]) [[1, "Fail"]],
    assert_equal
        (test [
            assert True "Pass", assert True "Pass", assert False "Fail"
        ]) [[2, "Fail"]]
]
