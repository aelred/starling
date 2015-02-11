from starling import thunk, linked_list, environment, function, star_type
from starling import error


class EmptyToken:
    def __init__(self, value=None):
        self.lazy = False

    @property
    def is_infix(self):
        return False

    def _display(self, indent=0):
        return '%s%s' % ('  ' * indent, self.__class__.__name__)


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
        try:
            result = self._eval(env)
        except Exception, e:
            # really simple stack trace
            raise error.StarlingRuntimeError("%s:\n\n%s" % (self, e))
        assert isinstance(result, star_type.StarObject) or callable(result)
        return result


class Script(Token, EvalToken):

    @property
    def body(self):
        return self._value[0]

    def _eval(self, env):
        return self.body.trampoline(env)


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


class Number(Terminator):
    def _eval(self, env):
        return star_type.Number(int(self.value))


class Char(Terminator):
    def _eval(self, env):
        return star_type.Char(self.value.decode('string_escape'))


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


class EmptyList(EmptyToken, EvalToken):

    def _eval(self, env):
        return linked_list.empty


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


class Bindings(Token):

    @property
    def elements(self):
        return self._value


class Binding(Token):

    @property
    def identifier(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]


class Lambda(Token, EvalToken):

    @property
    def parameter(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _eval(self, env):
        return function.Lambda(self.parameter.value, self.body, env)


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


class Export(Token, EvalToken):

    @property
    def identifiers(self):
        return self._value

    def _eval(self, env):
        exports = dict([(ex.value, thunk.Thunk(ex, ex.value, env))
                        for ex in self.identifiers])
        return star_type.Module(exports)


class Strict(Token, EvalToken):

    def __init__(self, value):
        self.lazy = False
        Token.__init__(self, value)

    @property
    def body(self):
        return self._value[0]

    def _eval(self, env):
        return lambda: self.body.eval(env)
