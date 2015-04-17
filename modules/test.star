let

enumerate = xs -> zip nats xs,

assert = pred message -> 
    if pred
    then {pass=True}
    else {pass=False, message=message},

assert_equal = x y -> assert (x==y) (join [repr x, " != ", repr y]),

assert_unequal = x y -> assert (x!=y) (join [repr x, " == ", repr y]),

test = map (t -> if t.pass then {pass=True} else t),

report = fail_fast results -> let

    # if fail_fast, only examine up to the first failing test
    filter_results =
        if fail_fast
        then let 
        split = span (.pass) results in 
        split._0 ++ (take 1 split._1)
        else results,

    # print a dot for every passing test and an 'F' for every failing test
    dots = map (t -> if t.pass then '.' else 'F') filter_results,

    # get numbered failing tests
    fails = filter (t -> not (t._1).pass) (enumerate filter_results),
    fail_message = 
        t -> join ["FAIL: Test ", str t._0, "\n", (t._1).message, "\n"],

    # string details of each failing test    
    detail = 
        if fails == []
        then "OK"
        else join (map fail_message fails) in

    join [dots, "\n", detail]

in export assert assert_equal assert_unequal test report
