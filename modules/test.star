let

enumerate = \xs: zip nats xs,

assert = \pred message: 
    if pred
    then {pass=True}
    else {pass=False, message=message},

enum unequal,

assert_equal = \x y: assert (x=y) {type=unequal, x=x, y=y},

fold_test = \t fails: let
    index = t@0, assertion = t@1 in
    if assertion.pass
    then fails 
    else {index=index, message=assertion.message} : fails,

test = fold fold_test [] >> enumerate

in export assert assert_equal test unequal
