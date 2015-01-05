letall
(
# basic logic
not (\ x (if x False True))
or (\ x (\ y (if x True (if y True False))))
and (\ x (\ y (if x (if y True False) False)))
# id returns itself
id (\ x x)
# const returns a function that always yields the given argument
const (\ y)

# comparison operators
>= (\ x (\ y (not (< x y))))
<= (\ x (\ y (not (> x y))))

# max and min functions
max (\ x (\ y (if (> x y) x y)))
min (\ x (\ y (if (< x y) x y)))

# fold returns the function folded over the given list
fold 
(
    \ f 
    (
        \ init 
        (
            \ xs
            (
                if (= xs [])
                init
                (f (head xs) (fold f init (tail xs)))
            )
        )
    )
)

# map returns the result of applying a function to every element in the list
map
(
    \ f
    (fold (\ x (\ accum (cons (f x) accum))) [])
)

# filter returns all elements in the list that satisfy the function
filter
(
    \ f 
    (fold (\ x (\ accum (if (f x) (cons x accum) accum))) [])
)

# take returns the first n elements from the list
take
(
    \ n 
    (
        \ xs
        (
            if (= n 0)
            []
            (cons (head xs) (take (- n 1) (tail xs)))
        )
    )
)

# range returns a range of numbers from start (inclusive) to end (exclusive)
range
(
    \ start 
    (
        \ end
        (
            if (= start end)
            []
            (cons start (range (+ start 1) end))
        )
    )
)

# nats returns all the natural numbers starting from 0
nats 
(
    let nats_ (\ n (cons n (nats_ (+ n 1))) )
    (nats_ 0)
)

# cat returns the concatenation of two lists
cat (\ xs (\ ys (fold cons ys xs)))

# sort returns a sorted version of the list
sort
(
    \ xs
    (
        if (= xs [])
        []
        (
            letall (
                pivot (head xs)
                less (filter (>= pivot) (tail xs))
                more (filter (< pivot) (tail xs))
            )
            (cat (sort less) (cons pivot (sort more)))
        )
    )
)
)
