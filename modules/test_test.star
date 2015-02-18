import test in 
test [
    assert_equal (assert True "Oh dear") {pass=True},
    assert_equal 
        (assert False "That's right") 
        {message="That's right", pass=False},

    assert_equal (assert_equal 3 3) {pass=True},
    assert_equal (assert_equal 3 (10 - 6)) 
        {message="3 != 4", pass=False},

    assert_equal (test []) [],

    assert_equal
        (test [
            assert_equal 1 1,
            assert_equal False False,
            assert_equal True True,
            assert True "Bad constants"
        ]) [],

    assert_equal 
        (test [assert False "FAILURE"]) 
        [{index=0, message="FAILURE"}],

    assert_equal
        (test [
            assert_equal "ab" "bc", assert (not True) "A"
        ]) [{index=0, message="\"ab\" != \"bc\""},
            {index=1, message="A"}],
    assert_equal
        (test [
            assert (3*3 = 9) "Pass", assert False "Fail", assert True "Pass"
        ]) [{index=1, message="Fail"}],
    assert_equal
        (test [
            assert True "Pass", assert True "Pass", assert False "Fail"
        ]) [{index=2, message="Fail"}]
]
