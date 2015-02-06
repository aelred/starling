let

enumerate = \xs: zip nats xs,

index = @0, pred = (@0) . (@1), message = (@1) . (@1),

assert = \pred message: [pred, if pred then "Pass" else message],

ass_pass = @0, ass_message = @1,

fold_test = \t fails: let
    ass = assert (pred t) (message t) in
    if ass_pass ass
    then fails 
    else [index t, ass_message ass] : fails,

test = fold fold_test [] . enumerate

in export assert test
