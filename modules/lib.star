let

# placeholder str and repr functions
str = obj -> obj.str obj,
repr = obj -> obj.repr obj,

# the empty list
empty_list = {
    str = self -> "[]",
    repr = self -> "[]"
},

intersperse = x xs ->
    if xs == []
    then []
    else if xs.tail == []
    then [xs.head]
    else xs.head : (x : (intersperse x xs.tail)),

# list constructor
: = x xs -> {
    head = x, 
    tail = xs,

    str = self -> 
        join ["[", join (intersperse ", " (map (y -> y.repr y) self)), "]"],

    repr = self -> self.str self
},

# basic logic
not = x -> if x then False else True,
or = x y -> if x then True else if y then True else False,
and = x y -> if x then (if y then True else False) else False,
any = foldr (or) False,
all = foldr (and) True,

# useful, short if construct
? = p c a -> if p then c else a,
# id returns itself
id = x -> x,
# const returns a function that always yields the given argument
const = x y -> x,

# function composition
>> = f g x -> f (g x),

# transform a function that takes a pair into a curried function
curry = f x y -> f (x, y),

# transform a curried function into one that takes a pair
uncurry = f xs -> f xs._0 xs._1,

# access array elements
@ = xs n -> if n == 0 then xs.head else xs.tail@(strict n-1),

# comparison operators
!= = x y -> not (x == y),
< = x y -> not (y <= x),
> = x y -> not (x <= y),
>= = x y -> not (y > x),

# max and min functions
max = x y -> x > y? x y,
min = x y -> x < y? x y,

# sum of a list of numbers
sum = foldl (+) 0,

# list contains given element
has = xs x -> any (map (== x) xs),

# swap function arguments
flip = f x y -> f y x,

# return the function folded from the right over the given list
foldr = f init xs -> 
    if xs == []
    then init
    else f xs.head (foldr f init xs.tail),

# return the function folded from the left over the given list
foldl = f init xs ->
    if xs == []
    then init
    else foldl f (strict f init xs.head) xs.tail,

# fold is a synonoym for foldr
fold = foldr,

# left fold where the first element is the initial value
foldr1 = f xs -> foldr f xs.head xs.tail,

# left fold where the first element is the initial value
foldl1 = f xs -> foldl f xs.head xs.tail,

# fold1 is a synonym for foldr1
fold1 = foldr1,

# return the result of applying a function to everything in the list
map = f -> fold (x accum -> f x : accum) [],

# return all elements in the list that satisfy the function
filter = f -> fold (x accum -> if f x then x : accum else accum) [],

# returns elements while predicate is true and the remainder of the list
span = p xs -> let
    span_ = span p xs.tail in
    if xs == [] or (not >> p xs.head)
    then ([], xs)
    else (xs.head : span_._0, span_._1),

# returns elements while predicate is false and the remainder of the list
break = p -> span (not >> p),    

# return the first n elements from the list
take = n xs ->
    if (n == 0) or (xs == [])
    then []
    else xs.head : (take (n - 1) xs.tail),

# return elements while predicate is true
take_while = p xs -> (span p xs)._0,

# return elements until predicate is true
take_until = p -> take_while (not >> p),

# drop the first n elements from the list
drop = n xs ->
    if (n == 0) or (xs == [])
    then xs
    else drop (n-1) xs.tail,

# drop elements while predicate is true
drop_while = p xs -> (span p xs)._1,

# drop elements until the predicate is true
drop_until = p -> drop_while (not >> p),

# join a list of lists into a single list
join = fold cat [],

# return all numbers between start (inclusive) and end (exclusive)
range = start end -> 
    if start == end
    then []
    else start : (range (start + 1) end),

# return all the natural numbers starting from 0
nats = let nats_ = n -> n : (nats_ (n + 1)) in nats_ 0,

# return the length of a list
length = foldl (const >> (+1)) 0,

# reverse a list
reverse = foldl (flip (:)) [],

# return the concatenation of two lists
cat = xs ys -> fold (:) ys xs,

# zip two lists together
zip = xs ys -> 
    if (xs == []) or (ys == [])
    then []
    else (xs.head, ys.head) : (zip xs.tail ys.tail),

# unzips a zipped list
unzip = 
    let f = xy accum -> 
        let 
            x = xy._0,
            y = xy._1,
            xs = accum._0,
            ys = accum._1 in 
        (x:xs, y:ys)
    in fold f ([], []),

# return a sorted version of the list
sort = xs ->
    if xs == []
    then []
    else let 
        pivot = xs.head,
        less = filter (< pivot) xs.tail,
        more = filter (>= pivot) xs.tail in 
    cat (sort less) (pivot : (sort more))

in export 
    str repr empty_list : not or and any all ? id const >> curry uncurry @ != 
    < >= > max min sum flip has foldr foldl fold foldr1 foldl1 fold1 map 
    filter span break take take_while take_until drop drop_while drop_until 
    join range nats length reverse cat zip unzip sort
