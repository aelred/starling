let
parser = import parser,
sp = import starparse,
t = import startoken,
starlex = import starlex,
test = import test,
?= = test.assert_equal,
?!= = test.assert_unequal,

tree = parser.tree,
leaf = parser.leaf,

parse = sp.parse >> starlex.tokenize in

test.test [
    (parse "1") ?= [leaf t.number "1"],
    (parse "x") ?= [leaf t.prefix_id "x"],
    (parse "(foo x y) + 932") ?= [
        tree t.apply [
            tree t.apply [
                leaf t.prefix_id "foo",
                leaf t.prefix_id "x",
                leaf t.prefix_id "y"
            ],
            leaf t.infix_id "+",
            leaf t.number "932"
        ]
    ],
    (parse "let x = foo 3, y = 2 in x + y") ?= [
        tree t.let_expr [
            tree t.bindings [
                tree t.binding [
                    leaf t.prefix_id "x",
                    tree t.apply [
                        leaf t.prefix_id "foo",
                        leaf t.number "3"
                    ]
                ],
                tree t.binding [
                    leaf t.prefix_id "y",
                    leaf t.number "2"
                ]
            ],
            tree t.apply [
                leaf t.prefix_id "x",
                leaf t.infix_id "+",
                leaf t.prefix_id "y"
            ]
        ]
    ],
    (parse 
    "if True then if False then 1 else 2 else if True then 3 else 4") ?= [
        tree t.if_expr [
            leaf t.bool "True",
            tree t.if_expr [
                leaf t.bool "False",
                leaf t.number "1",
                leaf t.number "2"
            ],
            tree t.if_expr [
                leaf t.bool "True",
                leaf t.number "3",
                leaf t.number "4"
            ]
        ]
    ],
    (parse "let map = f -> fold (x accum -> f x : accum) [] in 3") ?= [
        tree t.let_expr [
            tree t.bindings [
                tree t.binding [
                    leaf t.prefix_id "map",
                    tree t.lambda [
                        leaf t.prefix_id "f",
                        tree t.apply [
                            leaf t.prefix_id "fold",
                            tree t.lambda [
                                leaf t.prefix_id "x",
                                tree t.lambda [
                                    leaf t.prefix_id "accum",
                                    tree t.apply [
                                        leaf t.prefix_id "f",
                                        leaf t.prefix_id "x",
                                        leaf t.infix_id ":",
                                        leaf t.prefix_id "accum"
                                    ]
                                ]
                            ],
                            tree t.list []
                        ]
                    ]
                ]
            ],
            leaf t.number "3"
        ]
    ],
    (parse "let enum a b, enum c in \"hello\" ++ ['a', 'b']") ?= [
        tree t.let_expr [
            tree t.bindings [
                tree t.enum_expr [leaf t.prefix_id "a", leaf t.prefix_id "b"],
                tree t.enum_expr [leaf t.prefix_id "c"]
            ],
            tree t.apply [
                leaf t.string "\"hello\"",
                leaf t.infix_id "++",
                tree t.list [leaf t.char "'a'", leaf t.char "'b'"]
            ]
        ]
    ],
    (parse "(.<>) {x=1, y={}, z={<> = 3}}.z") ?= [
        tree t.apply [
            tree t.part_getter [leaf t.infix_id "<>"],
            tree t.getter [
                tree t.object [
                    tree t.binding [leaf t.prefix_id "x", leaf t.number "1"],
                    tree t.binding [leaf t.prefix_id "y", tree t.object []],
                    tree t.binding [
                        leaf t.prefix_id "z",
                        tree t.object [
                            tree t.binding [
                                leaf t.infix_id "<>",
                                leaf t.number "3"
                            ]
                        ]
                    ]
                ],
                leaf t.prefix_id "z"
            ]
        ]
    ],
    (parse "(1,)._0 + (2, 3,4)._1") ?= [
        tree t.apply [
            tree t.getter [
                tree t.tuple [leaf t.number "1"],
                leaf t.prefix_id "_0"
            ],
            leaf t.infix_id "+",
            tree t.getter [
                tree t.tuple [
                    leaf t.number "2", leaf t.number "3", leaf t.number "4"
                ],
                leaf t.prefix_id "_1"
            ]
        ]
    ],
    (parse "let p = import starparse.parse, |> = 3 in export p |>") ?= [
        tree t.let_expr [
            tree t.bindings [
                tree t.binding [
                    leaf t.prefix_id "p",
                    tree t.getter [
                        tree t.import_expr [leaf t.prefix_id "starparse"],
                        leaf t.prefix_id "parse"
                    ]
                ],
                tree t.binding [
                    leaf t.infix_id "|>",
                    leaf t.number "3"
                ]
            ],
            tree t.export_expr [
                leaf t.prefix_id "p",
                leaf t.infix_id "|>"
            ]
        ]
    ]
]
