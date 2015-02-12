from starling import thunk, linked_list, environment, function, star_type
from starling import error


_id = 0


def _get_id():
    global _id
    _id += 1
    return _id


class EmptyToken:
    def __init__(self, value=None):
        self.lazy = False

    @property
    def is_infix(self):
        return False

    def _display(self, indent=0):
        return '%s%s' % ('  ' * indent, self.__class__.__name__)

    def gen_python(self, indent=False):
        def add_indent(code):
            if indent:
                pad = '    '
            else:
                pad = ''
            return pad + ('\n'+pad).join(code.split('\n'))

        result = self._gen_python()

        if not self.lazy:
            # make sure this is evaluated immediately
            # done by utterly abusing docstrings
            result = '"""strict"""\n%s' % result

        return add_indent(result)


class Token(EmptyToken):

    def __init__(self, value):
        self._value = tuple(value)
        self.lazy = True

    def __eq__(self, other):
        try:
            return type(self) == type(other) and self._value == other._value
        except AttributeError:
            return False

    def _display(self, indent=0):
        child = '\n' + '\n'.join([t._display(indent+1) for t in self._value])
        return '%s%s:%s' % ('  ' * indent, self.__class__.__name__, child)

    def __str__(self):
        return self._display()


class EvalToken:

    def trampoline(self, env):
        result = self.eval(env)
        # 'trampoline' result, until it is not callable
        while callable(result):
            result = result()
        return result

    def eval(self, env):
        result = self._eval(env)
        assert isinstance(result, star_type.StarObject) or callable(result)
        return result


class Script(Token, EvalToken):

    @property
    def body(self):
        return self._value[0]

    def _eval(self, env):
        return self.body.trampoline(env)

    def _gen_python(self):
        return """
import star_type, linked_list, error

def _trampoline(f):
    f = f()
    while True:
        try:
            f = f()
        except TypeError:
            return f

def _main():
    def _trampoline(f):
        f = f()
        while True:
            try:
                f = f()
            except TypeError:
                return f

    class _thunk:

        def __init__(self, f):
            self._f = f
            self._mem = None
            # if this function is strict, eval immediately
            if getattr(self._f, '__doc__', None) == 'strict':
                self()
                self.__doc__ = 'strict'

        def __call__(self):
            if self._mem is None:
                self._mem = _trampoline(self._f)
                self._f = None
            return self._mem

    def _True():
        return star_type.Boolean(True)
    def _False():
        return star_type.Boolean(False)

    def _p():
        return lambda a: lambda: lambda b: a().add(b())
    def _s():
        return lambda a: lambda: lambda b: a().sub(b())
    def _a():
        return lambda a: lambda: lambda b: a().mul(b())
    def _d():
        return lambda a: lambda: lambda b: a().div(b())
    def mod():
        return lambda a: lambda: lambda b: a().mod(b())
    def pow():
        return lambda a: lambda: lambda b: a().pow(b())
    def _e():
        return lambda a: lambda: lambda b: a().eq(b())
    def _le():
        return lambda a: lambda: lambda b: a().le(b())

    def head():
        return lambda xs: xs().head()
    def tail():
        return lambda xs: xs().tail()

    def _c():
        return lambda x: lambda: lambda xs: linked_list.List(x, xs)
    def _chr():
        return lambda x: star_type.Char(chr(x().value))
    def _ord():
        return lambda c: star_type.Number(ord(c().value))

%s

try:
    _result = _trampoline(_main)
except NameError, e:
    raise error.StarlingRuntimeError(str(e))
        """ % self.body.gen_python(True)

    def wrap_import(self, imp):
        return Script([Import([imp.body, self.body])])


class Terminator(Token, EvalToken):

    def __init__(self, value):
        self._value = value
        self.lazy = True

    @property
    def value(self):
        return self._value

    def _display(self, indent=0):
        return '%s%s: %s' % (
            '  ' * indent, self.__class__.__name__, self.value)


class Identifier(Terminator):
    def __init__(self, value, is_infix):
        Terminator.__init__(self, value)
        self._is_infix = is_infix

    @property
    def is_infix(self):
        return self._is_infix

    def _eval(self, env):
        return env.resolve(self.value)

    def python_name(self):
        convert = {
            '.': 'f', '+': 'p', '-': 's', '*': 'a', '/': 'd', '=': 'e',
            '<': 'l', '>': 'g', '?': 'q', ':': 'c', '@': 't', '!': 'x',
            '$': 'o'
        }

        if self.value in ['and', 'del', 'from', 'not', 'while', 'as', 'elif',
                          'global', 'or', 'with', 'assert', 'else', 'if',
                          'pass', 'yield', 'break', 'except', 'import',
                          'print', 'class', 'exec', 'in', 'raise', 'continue',
                          'finally', 'is', 'return', 'def', 'for', 'lambda',
                          'try', 'False', 'True', 'chr', 'ord']:
            return '_' + self.value
        elif any(x in self.value for x in convert.keys()):
            return '_' + ''.join([convert.get(c, c) for c in self.value])
        else:
            return self.value

    def _gen_python(self):
        return 'return %s' % self.python_name()


class Number(Terminator):
    def _eval(self, env):
        return star_type.Number(int(self.value))

    def _gen_python(self):
        return 'return star_type.Number(%s)' % self.value


class Char(Terminator):
    def _eval(self, env):
        return star_type.Char(self.value.decode('string_escape'))

    def _gen_python(self):
        return 'return star_type.Char(\'%s\')' % self.value


class Expression(Token, EvalToken):

    @property
    def operator(self):
        return self._value[0]

    @property
    def operand(self):
        return self._value[1]

    def _eval(self, env):
        operand = thunk.Thunk(self.operand, 'argument', env)
        return lambda: self.operator.trampoline(env).apply(operand)

    def _gen_python(self):
        i1 = _get_id()
        i2 = _get_id()
        it = _get_id()
        return (
            'def _f%s():\n%s\ndef _f%s():\n%s\n_t%s = _thunk(_f%s)\n'
            'return lambda: _trampoline(_f%s)(_t%s)' % (
                i1, self.operand.gen_python(True),
                i2, self.operator.gen_python(True), it, i1, i2, it))


class EmptyList(EmptyToken, EvalToken):

    def _eval(self, env):
        return linked_list.empty

    def _gen_python(self):
        return 'return linked_list.empty'


class List(Token, EvalToken):

    @property
    def head(self):
        return self._value[0]

    @property
    def tail(self):
        return self._value[1]

    def _eval(self, env):
        head = thunk.Thunk(self.head, 'head', env)
        tail = thunk.Thunk(self.tail, 'tail', env)
        return linked_list.List(head.dethunk, tail.dethunk)

    def _gen_python(self):
        result = ''

        # build the list in a flat way
        lists = []
        li = self
        while isinstance(li, List):
            lists.append(li)
            li = li.tail

        # last element is not an explicit list
        last = li
        i_last = _get_id()
        result += (
            'def _f%s():\n%s\n'
            '_t%s = _thunk(_f%s)\n' % (i_last, last.gen_python(True),
                                       i_last, i_last))

        for li in reversed(lists):
            i_head = _get_id()
            i_list = _get_id()
            result += (
                'def _f%s():\n%s\n'
                '_t%s = _thunk(_f%s)\n'
                'def _f%s():\n'
                '    return lambda: _c()(_t%s)()(_t%s)\n'
                '_t%s = _thunk(_f%s)\n' % (
                    i_head, li.head.gen_python(True), i_head, i_head, i_list,
                    i_head, i_last, i_list, i_list))
            i_last = i_list

        result += 'return _f%s' % i_last

        return result


class If(Token, EvalToken):

    @property
    def predicate(self):
        return self._value[0]

    @property
    def consequent(self):
        return self._value[1]

    @property
    def alternative(self):
        return self._value[2]

    def _eval(self, env):
        pred = self.predicate.trampoline(env)
        if pred.value is True:
            return lambda: self.consequent.eval(env)
        elif pred.value is False:
            return lambda: self.alternative.eval(env)
        else:
            raise error.StarlingRuntimeError("Type error")

    def _gen_python(self):
        i1 = _get_id()
        it = _get_id()
        i2 = _get_id()
        i3 = _get_id()
        return (
            'def _f%s():\n%s\ndef _f%s():\n%s\ndef _f%s():\n%s\n'
            '_t%s = _trampoline(_f%s).value\n'
            'if _t%s is True: return _f%s\n'
            'elif _t%s is False: return _f%s\n'
            'else: raise error.StarlingRuntimeError("Type error")' % (
                i1, self.predicate.gen_python(True),
                i2, self.consequent.gen_python(True),
                i3, self.alternative.gen_python(True), it, i1, it, i2, it, i3))


class Let(Token, EvalToken):

    @property
    def bindings(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _eval(self, env):
        bindings = dict([(b.identifier.value,
                          thunk.Thunk(b.body, b.identifier.value))
                        for b in self.bindings.elements])

        new_env = environment.Environment(env, bindings)
        for thunk_ in bindings.values():
            thunk_.env = new_env

        # dethunk any strict thunks
        for thunk_ in bindings.values():
            thunk_.strict_dethunk()

        return lambda: self.body.eval(new_env)

    def _gen_python(self):
        return '%s\n%s' % (self.bindings.gen_python(), self.body.gen_python())


class Bindings(Token):

    @property
    def elements(self):
        return self._value

    def _gen_python(self):
        return '\n'.join([e.gen_python() for e in self.elements])


class Binding(Token):

    @property
    def identifier(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _gen_python(self):
        return 'def %s():\n%s' % (self.identifier.python_name(),
                                  self.body.gen_python(True))


class Lambda(Token, EvalToken):

    @property
    def parameter(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _eval(self, env):
        return function.Lambda(self.parameter.value, self.body, env)

    def _gen_python(self):
        i = _get_id()
        return 'def _f%s(%s):\n%s\nreturn _f%s' % (
            i, self.parameter.python_name(), self.body.gen_python(True), i)


class Imports(Token):

    @property
    def elements(self):
        return self._value

    def _gen_python(self):
        return '\n'.join(['%s' % e.gen_python() for e in self.elements])


class Import(Token, EvalToken):

    @property
    def imports(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _eval(self, env):
        for imp in self.imports.elements:
            env = env.child(imp.eval(env.ancestor()).value)
        return lambda: self.body.eval(env)

    def _gen_python(self):
        return '%s\n%s' % (self.imports.gen_python(), self.body.gen_python())


class Export(Token, EvalToken):

    @property
    def identifiers(self):
        return self._value

    def _eval(self, env):
        exports = dict([(ex.value, thunk.Thunk(ex, ex.value, env))
                        for ex in self.identifiers])
        return star_type.Module(exports)

    def _gen_python(self):
        return ''


class Strict(Token, EvalToken):

    def __init__(self, value):
        Token.__init__(self, value)
        self.lazy = False

    @property
    def body(self):
        return self._value[0]

    def _eval(self, env):
        return lambda: self.body.eval(env)

    def _gen_python(self):
        return self.body.gen_python()
