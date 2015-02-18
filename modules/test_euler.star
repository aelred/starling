let test = import test in
test.test [
    test.assert_equal (import euler1) 233168,
    test.assert_equal (import euler2) 4613732
]
