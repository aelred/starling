let fib = let fib_ = x y -> x : (fib_ y (x + y)) in fib_ 0 1 in
let even = x -> x mod 2 = 0 in
sum (take_while (<= 4000000) (filter even fib))
