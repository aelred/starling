let

enumerate = xs -> zip nats xs,

assert = pred message -> 
    if pred
    then {pass=True}
    else {pass=False, message=message},

assert_equal = x y -> assert (x==y) (join [repr x, " != ", repr y]),

assert_unequal = x y -> assert (x!=y) (join [repr x, " == ", repr y]),

test = asserts -> {
    tests = map (t -> if t.pass then {pass=True} else t) asserts, 
    str = self -> report self.tests
},

report = results -> let
    # do all tests pass?
    pass = all (map (.pass) results),

    # get a message for failing tests and a single '.' for passes
    test_message = t ->
        if t._1.pass
        then "."
        else join ["F\nFAIL: Test ", str t._0, "\n", t._1.message, "\n"],

    test_messages = join (map test_message (enumerate results)),

    final_message = if pass then "OK" else "FAIL" in

    join [test_messages, "\n", final_message]

in export assert assert_equal assert_unequal test
