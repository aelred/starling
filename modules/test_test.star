let 
t = import test,
test = t.test,
assert = t.assert,
?= = t.assert_equal,
?!= = t.assert_unequal,
report = t.report in 
test [
    (assert True "Oh dear") ?= {pass=True},
    (assert False "That's right") ?= {message="That's right", pass=False},

    (3 ?= 3) ?= {pass=True},
    (3 ?= (10 - 6)) ?= {message="3 != 4", pass=False},
    (3 ?!= 3) ?= {message="3 == 3", pass=False},
    (3 ?!= 4) ?= {pass=True},

    (test []) ?= [],

    (test [1?=1, False?=False, True?=True, assert True "Bad constants"]) ?= 
    [{pass=True}, {pass=True}, {pass=True}, {pass=True}],

    (test [assert False "FAILURE"]) ?= [{pass=False, message="FAILURE"}],

    (test ["ab" ?= "bc", assert (not True) "A" ]) ?= 
    [{pass=False, message="\"ab\" != \"bc\""}, {pass=False, message="A"}],
    
    (test [assert (3*3 == 9) "Pass", assert False "Fail", assert True "Pass"]) 
    ?= [{pass=True}, {pass=False, message="Fail"}, {pass=True}],

    (test [assert True "Pass", assert True "Pass", assert False "Fail"]) ?=
    [{pass=True}, {pass=True}, {pass=False, message="Fail"}],

    (report False (test [assert True "A", assert True "B", assert True "C"]))
    ?= "...\nOK",

    (report False (test [
        assert True "A", 
        assert True "B", 
        assert False "yup",
        assert False "yes",
        assert True "C"
    ])) ?=
    "..FF.\nFAIL: Test 2\nyup\nFAIL: Test 3\nyes\n",

    (report True (test [
        assert True "A", 
        assert True "B", 
        assert False "yup",
        assert False "yes",
        assert True "C"
    ])) ?=
    "..F\nFAIL: Test 2\nyup\n"
]
