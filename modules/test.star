let

enumerate = \xs: zip nats xs,

assert = \pred message: 
    if pred
    then {pass=True}
    else {pass=False, message=message},

assert_equal = \x y: assert (x=y) (join [repr x, " != ", repr y]),

assert_unequal = \x y: assert (x!=y) (join [repr x, " = ", repr y]),

test = map (\t: if t.pass then {pass=True} else t),

report = \results: let
    dot = \t: if t.pass then '.' else 'F',
    dots = map dot results,
    fails = filter (\t: not (t._1).pass) >> enumerate results,
    fail_message = 
        \t: join ["FAIL: Test ", str t._0, "\n", (t._1).message, "\n"],
    detail = 
        if fails = []
        then "OK"
        else join (map fail_message fails) in
    join [dots, "\n", detail]

in export assert assert_equal assert_unequal test report
