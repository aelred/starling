let
d = import dict,
test = import test,

?= = test.assert_equal,
?!= = test.assert_unequal,

dict = d.dict,
get = d.get,
get_def = d.get_def,
size = d.size,
keys = d.keys,
values = d.values,
items = d.items,
has_key = d.has_key,
put = d.put,
put_all = d.put_all,
rem = d.rem,

alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
digits = "0123456789",
dict1 = dict (zip nats alpha),
dict2 = dict (zip digits nats) in

test.test [
    size dict1 ?= 26,
    size dict2 ?= 10,

    get 0 dict1 ?= 'A',
    get 10 dict1 ?= 'K',
    get 25 dict1 ?= 'Z',
    get '0' dict2 ?= 0,
    get '8' dict2 ?= 8,
    get '9' dict2 ?= 9,

    get_def '_' 9 dict1 ?= 'J',
    get_def '_' 26 dict1 ?= '_',

    keys dict1 ?= (range 0 26),
    keys dict2 ?= digits,
    values dict1 ?= alpha,
    values dict2 ?= (range 0 10),
    items dict1 ?= (zip nats alpha),
    items dict2 ?= (zip digits nats),

    has_key 0 dict1 ?= True,
    has_key 10 dict1 ?= True,
    has_key 25 dict1 ?= True,
    has_key (0-1) dict1 ?= False,
    has_key 26 dict1 ?= False,
    has_key '0' dict2 ?= True,
    has_key '2' dict2 ?= True,
    has_key '9' dict2 ?= True,

    put 2 'C' dict1 ?= dict1,
    get 2 (put 2 '@' dict1) ?= '@',
    get 30 (put 30 'A' dict1) ?= 'A',

    put '2' 2 dict2 ?= dict2,
    get '5' (put '5' 10 dict2) ?= 10,

    put_all [(0, 'a'), (10, 'k')] dict1 ?= 
    (dict (zip nats "aBCDEFGHIJkLMNOPQRSTUVWXYZ")),

    has_key '4' (rem '4' dict2) ?= False
]
