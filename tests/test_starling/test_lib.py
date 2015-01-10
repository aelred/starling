from util import programs


@programs(True)
def test_math():
    return {
        '(max 4 9)': '9',
        '(max 15 15)': '15',
        '(min 4 9)': '4',
        '(min 2 2)': '2',
        'head nats': '0',
        'take 5 nats': '[0 1 2 3 4]',
        'sum []': '0',
        'sum [145]': '145',
        'sum [5 1 1 10]': '17',
        'zip [1 2 3] ["a" "b" "c"]': '[[1 "a"] [2 "b"] [3 "c"]]',
        'unzip [[1 "a"] [2 "b"] [3 "c"]]': '[[1 2 3] ["a" "b" "c"]]',
        'zip [1 2] ["a" "b" "c"]': '[[1 "a"] [2 "b"]]',
        'unzip [[1 "a"] [2 "b"]]': '[[1 2] ["a" "b"]]',
        'zip [1 2 3] []': '[]',
        'unzip []': '[[] []]'
    }


@programs(True)
def test_logic():
    return {
        '<= 4 6': 'True',
        '<= 6 6': 'True',
        '<= 6 4': 'False',
        '>= 4 6': 'False',
        '>= 6 6': 'True',
        '>= 6 4': 'True',
        'not False': 'True',
        'not True': 'False',
        'and (= 1 1) (= 2 2)': 'True',
        'and (= 1 1) (= 2 1)': 'False',
        'and (False) (False)': 'False',
        'or True True': 'True',
        'or True False': 'True',
        'or (= False True) False': 'False',
        'any [True True True]': 'True',
        'any [True False False]': 'True',
        'any [False False False]': 'False',
        'all [True True True]': 'True',
        'all [False True False]': 'False',
        'all [False False False]': 'False'
    }


@programs(True)
def test_lazy():
    # (let f=f in f) means 'define a function f that calls f, then call f.
    # recurses forever. If it ever evaluates, the script will not terminate
    return {
        'or True (let f=f in f)': 'True',
        'and False (let f=f in f)': 'False',
        '(const "ok") (let f=f in f)': '"ok"',
    }


@programs(True)
def test_partial():
    return {
        'map (* 2) [1 2 3]': '[2 4 6]',
        'filter (= "a") ["a" "b" "a" "a"]': '["a" "a" "a"]'
    }


@programs(True)
def test_misc():
    return {
        'id 50': '50',
        '(id not) False': 'True',
        'id "hi"': '"hi"',
        '(const 4) "a"': '4',
        '(const []) []': '[]'
    }


@programs(True)
def test_list_ops():
    return {
        'map not [False True False False]': '[True False True True]',
        'fold + 0 [1 10 100 1000]': '1111',
        'filter (const True) [1 2 3 4 5]': '[1 2 3 4 5]',
        'filter (const False) ["a" "b" "c"]': '[]',
        'filter (< 5) [1 100 5 7 2 10]': '[100 7 10]',
        'take 0 [1 2 3]': '[]',
        'take 1 [1 2 3]': '[1]',
        'take 2 [1 2]': '[1 2]',
        'cat [] []': '[]',
        'cat [1 2] []': '[1 2]',
        'cat [] [3 4]': '[3 4]',
        'cat [1 2] [3 4]': '[1 2 3 4]',
        'sort [1 2 3 4]': '[1 2 3 4]',
        'sort [2 4 1 3]': '[1 2 3 4]',
        'sort [4 3 2 1]': '[1 2 3 4]',
        'length []': '0',
        'length ["hello"]': '1',
        'length (take 5 nats)': '5',
        'reverse [1 2 3]': '[3 2 1]',
        'reverse []': '[]',
        'reverse [5]': '[5]'
    }


@programs(True)
def test_range():
    return {
        'range 0 0': '[]',
        'range 0 4': '[0 1 2 3]',
        'range 10 10': '[]',
        'range 9 10': '[9]'
    }
