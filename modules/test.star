let

enumerate = \xs: zip nats xs,

index = @0, pred = @1,

fold_test = \t fails: if pred t then fails else index t : fails,
test = fold fold_test [] . enumerate

in export test
