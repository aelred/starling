let 
mult = x y -> (x mod y) = 0,
mult_any = ys x -> any (map (mult x) ys) in
sum (filter (mult_any [3, 5]) (range 0 1000))
