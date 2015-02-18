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
        ]) [{pass=True}, {pass=True}, {pass=True}, {pass=True}],

    assert_equal 
        (test [assert False "FAILURE"]) 
        [{pass=False, message="FAILURE"}],

    assert_equal
        (test [
            assert_equal "ab" "bc", assert (not True) "A"
        ]) [{pass=False, message="\"ab\" != \"bc\""},
            {pass=False, message="A"}],
    assert_equal
        (test [
            assert (3*3 = 9) "Pass", assert False "Fail", assert True "Pass"
        ]) [{pass=True}, {pass=False, message="Fail"}, {pass=True}],
    assert_equal
        (test [
            assert True "Pass", assert True "Pass", assert False "Fail"
        ]) [{pass=True}, {pass=True}, {pass=False, message="Fail"}],

    assert_equal
        (report (test [
            assert True "A", 
            assert True "B", 
            assert True "C"
        ]))
        "...\nOK",

    assert_equal
        (report (test [
            assert True "A", 
            assert True "B", 
            assert False "yup",
            assert False "yes",
            assert True "C"
        ]))
        "..FF.\nFAIL: Test 2\nyup\nFAIL: Test 3\nyes\n"
]
