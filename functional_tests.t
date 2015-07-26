When run without arguments, should display a REPL:

  $ $TESTDIR/bin/starling
  >>>  (no-eol)

  $ $TESTDIR/bin/starling <<EOF
  > 100
  > True
  > 
  > EOF
  >>> 100
  >>> True
  >>>  (no-eol)

  $ $TESTDIR/bin/starling <<EOF
  > 1+2
  > True and False
  > EOF
  >>> 3
  >>> False
  >>>  (no-eol)

When run with a single argument, load that module and do not give prompt:

  $ $TESTDIR/bin/starling euler1
  233168
