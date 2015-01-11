let
# basic logic
not = \x: x? False True,
or = \x y: if x then True else if y then True else False,
and = \x y: if x then (if y then True else False) else False,
any = fold (or) False,
all = fold (and) True,

# useful, short if construct
? = \p c a: if p then c else a,
# id returns itself
id = \x: x,
# const returns a function that always yields the given argument
const = \x y: x,

# function composition
. = \f g x: f (g x),

# comparison operators
< = \x: not . (<= x),
> = \x y: not (x <= y),
>= = \x: not . (> x),

# max and min functions
max = \x y: x > y? x y,
min = \x y: x < y? x y,

# sum of a list of numbers
sum = fold (+) 0,

# return the function folded from the right over the given list
foldr = \f init xs: 
    if xs = []
    then init
    else f . head xs (foldr f init . tail xs),

# return the function folded from the left over the given list
foldl = \f init xs:
    if xs = []
    then init
    else foldl f (f init . head xs) . tail xs,

# fold is a synonoym for foldr
fold = foldr,

# return the result of applying a function to everything in the list
map = \f: fold (\x accum: f x : accum) [],

# return all elements in the list that satisfy the function
filter = \f: fold (\x accum: if f x then x : accum else accum) [],

# return the first n elements from the list
take = \n xs:
    if n = 0
    then []
    else head xs : (take (n - 1) . tail xs),

# return elements while predicate is true
take_while = \p xs: 
    if xs = [] or (not . p . head xs)
    then []
    else head xs : (take_while p (tail xs)),

# return all numbers between start (inclusive) and end (exclusive)
range = \start end: 
    if start = end
    then []
    else start : (range (start + 1) end),

# return all the natural numbers starting from 0
nats = let nats_ = \n: n : (nats_ (n + 1)) in nats_ 0,

# return the length of a list
length = fold (\x: +1) 0,

# reverse a list
reverse = fold (\x accum: cat accum [x]) [],

# return the concatenation of two lists
cat = \xs ys: fold (:) ys xs,

# zip two lists together
zip = \xs ys: 
    if xs = [] or (ys = [])
    then []
    else [head xs, head ys] : (zip (tail xs) (tail ys)),

# unzips a zipped list
unzip = 
    let f = \xy accum: 
        let 
            x = head xy,
            y = head . tail xy,
            xs = head accum,
            ys = head . tail accum in 
        [x:xs, y:ys] 
    in fold f [[], []],

# return a sorted version of the list
sort = \xs:
    if xs = []
    then []
    else let 
        pivot = head xs,
        less = filter (< pivot) . tail xs,
        more = filter (>= pivot) . tail xs in 
    cat (sort less) (pivot : (sort more))

in export 
    not or and any all ? id const . < >= > max min sum foldr foldl fold map
    filter take take_while range nats length reverse cat zip unzip sort
