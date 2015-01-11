let mult = \x y: x mod y = 0 in
let mult_all = \ys x: all (map (mult x) ys) in
sum (filter (mult_all [3, 5]) (range 0 1000))
