# starling

A pure and lazy functional language.

## Getting started ##

To install, run:

    $ python setup.py install

You can start the starling interpreter with the command:

	$ starling

## Examples ##

You can do basic arithmetic (but no operator precedence yet):

	>>> ((1 + 2) * 8) pow 2
	576
	>>> (702 / 2) mod 8
	7

Curried functions and list operations:

	>>> map (*2) (range 0 10)
	[0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
	>>> sort [3, 1, 10]
	[1, 3, 10]

Infinite lists, nested scopes and functions/lambdas:
	
	>>> let is_odd = (x -> (x mod 2) != 0) in take 5 >> (filter is_odd) nats
	[1, 3, 5, 7, 9]

Concise, JSON-esque object definitions:

	>>> shopping_list = [{name="eggs", price=2}, {name="milk", price=3}]
	>>> eggs = shopping_list@0
	>>> eggs.price
	2
	>>> eggs.name
	eggs
	>>> map (.name) shopping_list
	["eggs", "milk"]

Importing modules:

	>>> re = import regex
	>>> re.match "(mur)+" "murmurmurmur"
	{match=True, rem=[], str="murmurmurmur"}

## What's next? ##

 - Compilation to LLVM
 - Bootstrapping the compiler in Starling itself
 - Introduce type inference
 - Operator precedence
 - Support for I/O and impure behaviour
