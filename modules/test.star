let

enumerate = \xs: zip nats xs,

assert = \pred message: 
    if pred
    then {pass=True}
    else {pass=False, message=message},

assert_equal = \x y: assert (x=y) (join [str x, " != ", str y]),

test = map (\t: if t.pass then {pass=True} else t),

report = \results: let
    dot = \t: if t.pass then '.' else 'F',
    dots = map dot results,
    fails = filter (\t: not (t@1).pass) >> enumerate results,
    fail_message = 
        \t: join ["FAIL: Test ", str (t@0), "\n", (t@1).message, "\n"],
    detail = join (map fail_message fails) in
    join [dots, "\n", detail]

in export assert assert_equal test report
