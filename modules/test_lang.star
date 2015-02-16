import test in
test >> (map >> uncurry assert_equal) [
    # chars and strings
    ["", []],
    ['a', 'a'],
    ["Hello World!", "Hello World!"],
    [head "Hi", 'H'],
    [tail "Hi", "i"],
    [tail "a", []],
    ['H' : ('i' : []), "Hi"],
    [
        map chr [39, 92, 34, 8, 12, 10, 13, 9, 11, 69, 14, 83, 16, 7],
        "'\\\"\b\f\n\r\t\v\x45\x0e\123\20\7"
    ],
    [
        map ord ['\'', '\\', '"', '\b', '\f', '\n', '\r', '\t', '\v',
                 '\x45', '\x0e', '\123', '\20', '\7'],
        [39, 92, 34, 8, 12, 10, 13, 9, 11, 69, 14, 83, 16, 7]
    ],
    [chr 98, 'b'],
    [ord 'b', 98],
    ['Z', '\x5a'], 
    ['\x5a', '\x5A'], 
    ['\x5A', '\132'],
    ['\x20', ' '],
    ['a' <= 'b', True],
    ['5' <= '5', True],

    # maths
    [14, 14],
    [14 + 3, 17],
    [12 - 3, 9],
    [1 * 2, 2],
    [6 / 2, 3],
    [(3 + 2), 5],
    [(10 + (3 * 3)), 19],
    [10 mod 2, 0],
    [9 mod 2, 1],
    [6 mod 6, 0],
    [5 mod 3, 2],
    [5 pow 0, 1],
    [60 pow 1, 60],
    [5 pow 2, 25],
    [2 pow 8, 256],

    # infix operators
    [2 + 3, 5],
    [1 + 2 + 3, 6],
    [5 - 1 - 2, 2],
    [(+ 2) 3, 5],
    [(2 +) 3, 5],
    [(/ 2) 10, 5],
    [(10 /) 2, 5],

    # logic
    [3 = 0, False],
    [0 = 0, True],
    [4 <= 6, True],
    [6 <= 6, True],
    [6 <= 4, False],
    [False, False],
    [True, True],

    # if
    [if 2 <= 1 then "Oh dear..." else "Great!", "Great!"],

    # constants
    [let a=5 in a + 1, 6],
    [let x=2 in ((let x=10 in x) / x), 5],

    # functions
    [let square=\x: x * x in (square 5), 25],
    [let avg = (\ x y: ((x + y) / 2)) in (let a= 6 in (avg a 8)), 7],

    # lists
    [[], []],
    [[1], [1]],
    [[1, 2], [1, 2]],
    [head [1, 2, 3], 1],
    [tail [1, 2, 3], [2, 3]],
    [1 : [], [1]],
    [2 : [10], [2, 10]],
    [3 : (2 : (1 : [])), [3, 2, 1]],

    # recursion
    [
        let tri = \ x: (if x = 0 then 0 else (tri (x - 1)) + x) in (tri 4),
        10
    ],
    [
        let fib = \ x:
            if x = 0
            then 0
            else if x = 1
            then 1
            else fib (x - 1) + (fib (x - 2))
        in fib 6,
        8
    ],

    # objects
    [{}, {}],
    [{x=3}, {x=3}],
    [{} = {a=1}, False],
    [{n1=1} = {n2=1}, False],
    [{x='a'} = {x='b'}, False],
    [{a={t=[]}, b=[1]}, {a={t=[]}, b=[1]}],
    [let x=0 in {x=x}, {x=0}],
    [{x=3}.x, 3],
    [({a=1, b={c=2}}.b).c, 2],
    [{a=\x: x+1}.a 10, 11],
    [(.a) {a=10}, 10],

    # enums
    let enum a in [a, a],
    let enum a, enum b in [a = b, False],
    let enum a b in [a = b, False],
    let enum a b, x=a, y=a, z=b in 
    [all([a=a, a!=b, a=x, a!=z, x=y, x!=z]), True],
    let f = (\x: let enum a in a) in [f 1, f 1],  # referential transparency
    
    # comments
    [
        1, # this is a comment
        1
    ],
    [
        "hi", #so is this,
        "hi"
    ],
    [
        "# not this", #     and this!
        "# not this"
    ],
    [
        5 ,# return 5 
        5
    ],
    [
        # inverts a number
        let inv =
        (
            \ x:  # accepts one argument, x
            (    # and then... (this is my favourite bit)
                0 - x  # return 0 - x = -x
            )
        ) in
        inv 10,  # call with arg 10, should return -10
        0-10
    ],

    # partial application
    [(+ 3) 5, 8],

    # importing
    [import test_module in test_message, "Import successful!"]
]
