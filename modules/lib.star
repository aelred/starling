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

# transform a function that takes a two-element list into a curried function
curry = \f x y: f [x, y],

# transform a curried function into one that takes a two-element list
uncurry = \f xs: f (xs@0) (xs@1),

# access array elements
@ = \xs n: if n = 0 then head xs else (tail xs) @ (n - 1),

# comparison operators
< = \x: not . (<= x),
> = \x y: not (x <= y),
>= = \x: not . (> x),

# max and min functions
max = \x y: x > y? x y,
min = \x y: x < y? x y,

# sum of a list of numbers
sum = fold (+) 0,

# list contains given element
has = \xs x: any (map (= x) xs),

# swap function arguments
flip = \f x y: f y x,

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

# return elements until predicate is true
take_until = \p: take_while (not . p),

# drop the first n elements from the list
drop = \n xs:
    if n = 0
    then xs
    else drop (n-1) (tail xs),

# drop elements while predicate is true
drop_while = \p xs: 
    if (not (xs = [])) and (p . head xs)
    then drop_while p (tail xs)
    else xs,

# drop elements until the predicate is true
drop_until = \p: drop_while (not . p),

# join a list of lists into a single list
join = fold cat [],

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
    not or and any all ? id const . curry uncurry @ < >= > max min sum flip 
    has foldr foldl fold map filter take take_while take_until drop 
    drop_while drop_until join range nats length reverse cat zip unzip sort
