let

enumerate = \xs: zip nats xs,

index = @0, assertion = @1,

assert = \pred message: [pred, if pred then "Pass" else message],

ass_pass = @0, ass_message = @1,

fold_test = \t fails: 
    if ass_pass . assertion t
    then fails 
    else [index t, ass_message . assertion t] : fails,

test = fold fold_test [] . enumerate

in export assert test
