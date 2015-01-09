from starling import thunk, linked_list, environment, function


class Token:

    def __init__(self, value):
        self._value = tuple(value)

    def __eq__(self, other):
        return type(self) == type(other) and self._value == other._value

    def _display(self, indent=0):
        child = '\n' + '\n'.join([t._display(indent+1) for t in self._value])
        return '%s%s:%s' % ('  ' * indent, self.__class__.__name__, child)

    def __str__(self):
        return self._display()


class Terminator(Token):

    def __init__(self, value):
        self._value = value

    @property
    def value(self):
        return self._value

    def _display(self, indent=0):
        return '%s%s: %s' % (
            '  ' * indent, self.__class__.__name__, self.value)


class Identifier(Terminator):
    def eval(self, env):
        return env.resolve(self.value)


class Number(Terminator):
    def eval(self, env):
        return int(self.value)


class String(Terminator):
    def eval(self, env):
        return self.value


class Expression(Token):

    @property
    def operator(self):
        return self._value[0]

    @property
    def operand(self):
        return self._value[1]

    def eval(self, env):
        operator = self.operator.eval(env)
        operand = thunk.Thunk(self.operand, 'argument', env)
        return operator.apply(operand)


class List(Token):

    @property
    def elements(self):
        return self._value

    def eval(self, env):
        if len(self.elements) == 0:
            return linked_list.empty
        else:
            head = thunk.Thunk(self.elements[0], 'head', env)
            tail = thunk.Thunk(List(self.elements[1:]), 'tail', env)
            return linked_list.List(head, tail)


class If(Token):

    @property
    def predicate(self):
        return self._value[0]

    @property
    def consequent(self):
        return self._value[1]

    @property
    def alternative(self):
        return self._value[2]

    def eval(self, env):
        if self.predicate.eval(env):
            return self.consequent.eval(env)
        else:
            return self.alternative.eval(env)


class Let(Token):

    @property
    def bindings(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def eval(self, env):
        bindings = dict([(b.identifier.value,
                          thunk.Thunk(b.body, b.identifier.value))
                        for b in self.bindings.elements])

        new_env = environment.Environment(env, bindings)
        for thunk_ in bindings.values():
            thunk_.env = new_env

        return self.body.eval(new_env)


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


class Lambda(Token):

    @property
    def parameter(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def eval(self, env):
        return function.Lambda(self.parameter.value, self.body, env)


class Export(Token):

    @property
    def identifiers(self):
        return self._value

    def eval(self, env):
        exports = dict([(ex.value, thunk.Thunk(ex, ex.value, env))
                        for ex in self.identifiers])
        return environment.Environment(env.ancestor(), exports)


class None_(Token):
    def eval(self, env):
        return None
