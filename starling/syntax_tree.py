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
        if indent:
            pad = '    '
        else:
            pad = ''
        return pad + ('\n'+pad).join(self._gen_python().split('\n'))


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
def main():
    import star_type, linked_list

    def _True():
        return star_type.Boolean(True)
    def _False():
        return star_type.Boolean(False)

    def _p():
        return lambda a: lambda: lambda b: a().add(b())
    def _s():
        return lambda a: lambda: lambda b: a().sub(b())
    def _m():
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
        return lambda x: lambda xs: linked_list.List(x, xs)
    def _chr():
        return lambda x: star_type.Char(chr(x().value))
    def _ord():
        return lambda c: star_type.Number(ord(c().value))

%s

result = main()
        """ % self.body.gen_python(True)


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
            '.': 'd', '+': 'p', '-': 's', '*': 'a', '/': 'd', '=': 'e',
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
        i = _get_id()
        return 'def _f%s():\n%s\n%s()(_f%s)' % (
            i, self.operand.gen_python(True), self.operator.gen_python(), i)


class EmptyList(EmptyToken, EvalToken):

    def _eval(self, env):
        return linked_list.empty

    def _gen_python(self):
        return 'linked_list.empty'


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
        return linked_list.List(head, tail)

    def _gen_python(self):
        i1 = _get_id()
        i2 = _get_id()
        return (
            'def _f%s():\n%s\n'
            'def _f%s():\n%s\n'
            'return linked_list.LinkedList(f%s(), f%s())') % (
                i1, self.head.gen_python(True), i2, self.tail.gen_python(True),
                i1, i2)


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
        i = _get_id()
        return 'def _f%s():\n%s\nif _f%s():\n%s()\nelse:\n%s()' % (
            i, self.predicate.gen_python(True), i,
            self.consequent.gen_python(True),
            self.alternative.gen_python(True))


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
        return '# import stuff here\n%s' % self.body.gen_python()


class Export(Token, EvalToken):

    @property
    def identifiers(self):
        return self._value

    def _eval(self, env):
        exports = dict([(ex.value, thunk.Thunk(ex, ex.value, env))
                        for ex in self.identifiers])
        return star_type.Module(exports)

    def _gen_python(self):
        return 'return "EXPORT"'


class Strict(Token, EvalToken):

    def __init__(self, value):
        self.lazy = False
        Token.__init__(self, value)

    @property
    def body(self):
        return self._value[0]

    def _eval(self, env):
        return lambda: self.body.eval(env)
