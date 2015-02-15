import logging

# these are imported for execing starling scripts
from starling import star_type, linked_list, error  # NOQA
from starling.glob_env import *  # NOQA

_id = 0

log = logging.getLogger('starling.syntax_tree')


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


class Script(Token):

    @property
    def body(self):
        return self._value[0]

    def _gen_python(self):
        return (
            'def _main():\n'
            '%s\n'
            'try:\n'
            '    _result = trampoline(_main)\n'
            'except NameError, e:\n'
            '    raise error.StarlingRuntimeError(str(e))' % (
                self.body.gen_python(True)))

    def wrap_import(self, imp):
        return Script([Import([imp.body, self.body])])

    def evaluate(self):
        code = self.gen_python()
        log.debug('\n'.join(
            ['%d\t%s' % (i+1, c) for i, c in enumerate(code.split('\n'))]))
        exec code in globals(), locals()
        return _result


class Terminator(Token):

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
                          'try', 'False', 'True', 'chr', 'ord', 'trampoline',
                          'Thunk']:
            return self.value + '__'
        elif any(x in self.value for x in convert.keys()):
            return ''.join([convert.get(c, c) for c in self.value]) + '__'
        else:
            return self.value

    def _gen_python(self):
        return 'return %s' % self.python_name()


class Number(Terminator):
    def _gen_python(self):
        return 'return star_type.Number(%s)' % self.value


class Char(Terminator):
    def _gen_python(self):
        return 'return star_type.Char(\'%s\')' % self.value


class Expression(Token):

    @property
    def operator(self):
        return self._value[0]

    @property
    def operand(self):
        return self._value[1]

    def _gen_python(self):
        i1 = _get_id()
        i2 = _get_id()
        it = _get_id()
        return (
            'def _f%s():\n%s\ndef _f%s():\n%s\n_t%s = Thunk(_f%s)\n'
            'return lambda: trampoline(_f%s)(_t%s)' % (
                i1, self.operand.gen_python(True),
                i2, self.operator.gen_python(True), it, i1, i2, it))


class EmptyList(EmptyToken):

    def _gen_python(self):
        return 'return linked_list.empty'


class List(Token):

    @property
    def head(self):
        return self._value[0]

    @property
    def tail(self):
        return self._value[1]

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
            '_t%s = Thunk(_f%s)\n' % (i_last, last.gen_python(True),
                                      i_last, i_last))

        for li in reversed(lists):
            i_head = _get_id()
            i_list = _get_id()
            result += (
                'def _f%s():\n%s\n'
                '_t%s = Thunk(_f%s)\n'
                'def _f%s():\n'
                '    return lambda: c__()(_t%s)()(_t%s)\n'
                '_t%s = Thunk(_f%s)\n' % (
                    i_head, li.head.gen_python(True), i_head, i_head, i_list,
                    i_head, i_last, i_list, i_list))
            i_last = i_list

        result += 'return _t%s' % i_last

        return result


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

    def _gen_python(self):
        i1 = _get_id()
        it = _get_id()
        i2 = _get_id()
        i3 = _get_id()
        return (
            'def _f%s():\n%s\ndef _f%s():\n%s\ndef _f%s():\n%s\n'
            '_t%s = trampoline(_f%s).value\n'
            'if _t%s is True: return _f%s\n'
            'elif _t%s is False: return _f%s\n'
            'else: raise error.StarlingRuntimeError("Type error")' % (
                i1, self.predicate.gen_python(True),
                i2, self.consequent.gen_python(True),
                i3, self.alternative.gen_python(True), it, i1, it, i2, it, i3))


class Let(Token):

    @property
    def bindings(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

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


class Enum(Token):
    @property
    def identifiers(self):
        return self._value

    def _gen_python(self):
        names = [i.python_name() for i in self.identifiers]
        return '\n'.join('%s = star_type.Enum(\'%s\')' % (n, n)
                         for n in names)


class Lambda(Token):

    @property
    def parameter(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _gen_python(self):
        i = _get_id()
        return 'def _f%s(%s):\n%s\nreturn _f%s' % (
            i, self.parameter.python_name(), self.body.gen_python(True), i)


class Object(Token):
    @property
    def bindings(self):
        return self._value

    def _gen_python(self):
        names = [b.identifier.python_name() for b in self.bindings]
        return (
            '%s\n'
            'return star_type.Object({%s})'
        ) % ('\n'.join(b._gen_python() for b in self.bindings),
             ', '.join('\'%s\': Thunk(_o%s)' % (n, n) for n in names))


class ObjectBinding(Token):

    @property
    def identifier(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _gen_python(self):
        return 'def _o%s():\n%s' % (self.identifier.python_name(),
                                    self.body.gen_python(True))


class Accessor(Token):
    @property
    def body(self):
        return self._value[0]

    @property
    def attribute(self):
        return self._value[1]

    def _gen_python(self):
        i = _get_id()
        return (
            'def _f%s():\n'
            '%s\n'
            'return trampoline(_f%s).value[\'%s\']'
        ) % (i, self.body.gen_python(True), i, self.attribute.python_name())


class Imports(Token):

    @property
    def elements(self):
        return self._value

    def _gen_python(self):
        return '\n'.join(['%s' % e.gen_python() for e in self.elements])


class Import(Token):

    @property
    def imports(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _gen_python(self):
        return '%s\n%s' % (self.imports.gen_python(), self.body.gen_python())


class Export(Token):

    @property
    def identifiers(self):
        return self._value

    def _gen_python(self):
        return ''


class Strict(Token):

    def __init__(self, value):
        Token.__init__(self, value)
        self.lazy = False

    @property
    def body(self):
        return self._value[0]

    def _gen_python(self):
        return self.body.gen_python()
