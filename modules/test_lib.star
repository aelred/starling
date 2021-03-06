let 
t = import test,
?= = t.assert_equal,
?!= = t.assert_unequal
in 
t.test [
    # maths
    (max 4 9) ?= 9,
    (max 15 15) ?= 15,
    (min 4 9) ?= 4,
    (min 2 2) ?= 2,
    nats.head ?= 0,
    (take 5 nats) ?= [0, 1, 2, 3, 4],
    (sum []) ?= 0,
    (sum [145]) ?= 145,
    (sum [5, 1, 1, 10]) ?= 17,

    # logic
    2 ?= 2,
    2 ?!= 3,
    (2 < 0) ?= False,
    (0 < 2) ?= True,
    (0 < 0) ?= False,
    (4 >= 6) ?= False,
    (6 >= 6) ?= True,
    (6 >= 4) ?= True,
    (2 > 0) ?= True,
    (0 > 2) ?= False,
    (0 > 0) ?= False,
    (not False) ?= True,
    (not True) ?= False,
    ((1 == 1) and (2 == 2)) ?= True,
    ((1 == 1) and (2 == 1)) ?= False,
    (False and False) ?= False,
    (True or True) ?= True,
    (True or False) ?= True,
    ((False == True) or False) ?= False,
    (any [True, True, True]) ?= True,
    (any [True, False, False]) ?= True,
    (any [False, False, False]) ?= False,
    (all [True, True, True]) ?= True,
    (all [False, True, False]) ?= False,
    (all [False, False, False]) ?= False,

    # laziness
    (True or (let f=f in f)) ?= True,
    (False and (let f=f in f)) ?= False,
    ((const "ok") (let f=f in f)) ?= "ok",
    
    # tail call elimination test
    (sum (range 0 1000)) ?= 499500,
    (length (range 0 1000)) ?= 1000,
    (any (map (x -> x<0) (range 0 1000))) ?= False,
    (all (map (x -> x>=0) (range 0 1000))) ?= True,
    ((reverse (range 0 1000)).head) ?= 999,
    ((range 0 10000)@1000) ?= 1000,

    # partial application
    (map (* 2) [1, 2, 3]) ?= [2, 4, 6],
    (filter (== "a") ["a", "b", "a", "a"]) ?= ["a", "a", "a"],

    # miscellaneous functions
    (id 50) ?= 50,
    ((id not) False) ?= True,
    (id "hi") ?= "hi",
    ((const 4) "a") ?= 4,
    ((const []) []) ?= [],
    ((+ 1) >> (* 2) 3) ?= 7,
    ((flip take) nats 3) ?= [0, 1, 2],
    (curry (p -> p._0 + p._1) 3 8) ?= 11,
    (uncurry (+) (3, 8)) ?= 11,

    # list operations
    ([1] @ 0) ?= 1,
    ([1, 2, 3]@ 2) ?= 3,
    ("hello"@1) ?= 'e',
    (map not [False, True, False, False]) ?= [True, False, True, True],
    (fold (+) 0 [1, 10, 100, 1000]) ?= 1111,
    (foldr (+) 0 [1, 10, 100, 1000]) ?= 1111,
    (foldl (+) 0 [1, 10, 100, 1000]) ?= 1111,
    (fold (-) 10 [1, 2, 3]) ?= (0-8),
    (foldr (-) 10 [1, 2, 3]) ?= (0-8),
    (foldl (-) 10 [1, 2, 3]) ?= 4,
    (fold1 (-) [1, 2, 3]) ?= 0,
    (foldr1 (-) [1, 2, 3]) ?= 0,
    (foldl1 (-) [1, 2, 3]) ?= (0-4),
    (filter (const True) [1, 2, 3, 4, 5]) ?= [1, 2, 3, 4, 5],
    (filter (const False) ["a", "b", "c"]) ?= [],
    (filter (> 5) [1, 100, 5, 7, 2, 10]) ?= [100, 7, 10],
    (sort [1, 2, 3, 4]) ?= [1, 2, 3, 4],
    (sort [2, 4, 1, 3]) ?= [1, 2, 3, 4],
    (sort [4, 3, 2, 1]) ?= [1, 2, 3, 4],
    (length []) ?= 0,
    (length ["hello"]) ?= 1,
    (length (take 5 nats)) ?= 5,
    (reverse [1, 2, 3]) ?= [3, 2, 1],
    (reverse []) ?= [],
    (reverse [5]) ?= [5],
    ([1, 2, 3] has 3) ?= True,
    ("hello" has 'y') ?= False,
    ([1, 2, 3] has 9) ?= False,
    ("hello" has 'l') ?= True,
    (range 0 0) ?= [],
    (range 0 4) ?= [0, 1, 2, 3],
    (range 10 10) ?= [],
    (range 9 10) ?= [9],

    # list joining operations
    ([] ++ []) ?= [],
    ([1, 2] ++ []) ?= [1, 2],
    ([] ++ [3, 4]) ?= [3, 4],
    ([1, 2] ++ [3, 4]) ?= [1, 2, 3, 4],
    ("Hello " ++ "World") ?= "Hello World",
    (join [[1, 2, 3], [4, 5, 6]]) ?= [1, 2, 3, 4, 5, 6],
    (join ["Hello", " ", "World!"]) ?= "Hello World!",
    (zip [1, 2, 3] ["a", "b", "c"]) ?= [(1, "a"), (2, "b"), (3, "c")],
    (unzip [(1, "a"), (2, "b"), (3, "c")]) ?= ([1, 2, 3], ["a", "b", "c"]),
    (zip [1, 2] ["a", "b", "c"]) ?= [(1, "a"), (2, "b")],
    (unzip [(1, "a"), (2, "b")]) ?= ([1, 2], ["a", "b"]),
    (zip [1, 2, 3] []) ?= [],
    (unzip []) ?= ([], []),

    # take/drop operations
    (span (< 2) [1, 0, 1, 2, 5]) ?= ([1, 0, 1], [2, 5]),
    (span (const False) [1, 0, 1, 2, 5]) ?= ([], [1, 0, 1, 2, 5]),
    (span (const True) [1, 0, 1, 2, 5]) ?= ([1, 0, 1, 2, 5], []),
    (break (>= 2) [1, 0, 1, 2, 5]) ?= (span (< 2) [1, 0, 1, 2, 5]),
    (break (const False) [1, 0, 1, 2, 5]) ?= ([1, 0, 1, 2, 5], []),
    (break (const True) [1, 0, 1, 2, 5]) ?= ([], [1, 0, 1, 2, 5]),
    (take 0 [1, 2, 3]) ?= [],
    (take 1 [1, 2, 3]) ?= [1],
    (take 2 [1, 2]) ?= [1, 2],
    (take 5 [1, 2]) ?= [1, 2],
    (take_while (< 2) [1, 0, 1, 2, 5]) ?= [1, 0, 1],
    (take_while (const False) [1, 2, 3]) ?= [],
    (take_while (< 2) []) ?= [],
    (take_while (const True) [1, 2, 3]) ?= [1, 2, 3],
    (take_while (< 3) nats) ?= [0, 1, 2],
    (take_until (== 5) [0, 6, 4, 5]) ?= [0, 6, 4],
    (take_until (const True) nats) ?= [],
    (take_until (const False) [1, 2]) ?= [1, 2],
    (drop 0 [1, 2, 3]) ?= [1, 2, 3],
    (drop 1 [1, 2, 3]) ?= [2, 3],
    (drop 3 [1, 2, 3]) ?= [],
    (drop 10 [1]) ?= [],
    (drop_while (== 2) [2, 2, 2, 3, 1]) ?= [3, 1],
    (drop_while (const True) [1]) ?= [],
    (drop_while (const False) [2, 2, 3]) ?= [2, 2, 3],
    (drop_until (=='=') "x=2+3") ?= "=2+3",
    (drop_until (const False) "hello") ?= [],
    (drop_until (const True) [2, 2, 3]) ?= [2, 2, 3]
]
