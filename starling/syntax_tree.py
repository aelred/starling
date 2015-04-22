import logging
import os
from itertools import chain
import llvmlite.ir as ll
import llvmlite.binding as llvm
from starling import star_path

_id = 0

log = logging.getLogger('starling.syntax_tree')

_void = ll.VoidType()
_bool = ll.IntType(1)
_boolp = ll.PointerType(_bool)
_i8 = ll.IntType(8)
_i8p = ll.PointerType(_i8)
_i32 = ll.IntType(32)
_i32p = ll.PointerType(_i32)
_i64 = ll.IntType(64)

_binfunc = ll.FunctionType(_i8p, [_i8p, _i8p])

_global_ids = set(
    ['True', 'False', '+', '-', '*', '/', 'mod', 'pow', '==', '<='])


def _nest_function(module, helper, builder, env, free_ids, thunk=None):
    """ Create a nested LLVM function, binding all free identifiers. """
    func = ll.Function(module, helper['objfunc'], module.get_unique_name())
    func.linkage = 'private'
    func.args[0].name = 'env'
    fbuilder = ll.IRBuilder(func.append_basic_block())

    # ignore global identifiers
    free_ids = free_ids - _global_ids

    new_env = dict(env)

    if free_ids:
        # for each free identifier, pass it to the function and load it
        env_type = ll.ArrayType(helper['thp'], len(free_ids))
        env_ptr = fbuilder.bitcast(
            func.args[0], ll.PointerType(env_type), name='env_ptr')

        # TODO: Make sure this is the right size
        env_pass_ptr = builder.call(
            helper['malloc'],
            [ll.Constant(_i32, 8 * len(free_ids))], name='env_pass_ptr')
        env_pass_cast = builder.bitcast(
            env_pass_ptr, ll.PointerType(env_type), name='env_pass_cast')
        for index, ident in enumerate(free_ids):
            # write the value before calling
            index_val = [ll.Constant(_i32, 0), ll.Constant(_i32, index)]
            index_ptr = builder.gep(env_pass_cast, index_val, True, 'env_index')
            builder.store(env[ident], index_ptr)

            # read the value after calling
            read_ptr = fbuilder.gep(env_ptr, index_val, True, 'env_index')
            new_env[ident] = fbuilder.load(read_ptr, name=ident)
    else:
        # if there are no free identifiers, skip creating environment
        env_pass_ptr = ll.Constant(_i8p, None)

    # create a thunk combining the function and environment
    if thunk is None:
        thunk = builder.call(
            helper['make_thunk'], [env_pass_ptr, func], name='thunk')
    else:
        builder.call(helper['fill_thunk'], [thunk, env_pass_ptr, func])

    return fbuilder, new_env, thunk


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

    def free_identifiers(self):
        return set()


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

    def free_identifiers(self):
        ids = [v.free_identifiers() for v in self._value]
        if ids:
            return set.union(*ids)
        else:
            return set()


class Script(Token):

    @property
    def body(self):
        return self._value[0]

    def _gen_python(self):
        return (
            'from starling import star_type, error\n'
            'from starling.glob_env import *\n'
            'import imp\n'
            'def _main():\n'
            '%s\n'
            'def _result():\n'
            '    try:\n'
            '        return trampoline(_main)\n'
            '    except NameError, e:\n'
            '        raise error.StarlingRuntimeError(str(e))' % (
                self.body.gen_python(True)))

    def gen_llvm(self):
        llvm.initialize()
        llvm.initialize_native_target()
        llvm.initialize_native_asmprinter()

        module = ll.Module()

        thtype = module.context.get_identified_type('thunk')
        thp = ll.PointerType(thtype)
        cltype = module.context.get_identified_type('closure')
        objtype = module.context.get_identified_type('object')
        objp = ll.PointerType(objtype)

        objfunc = ll.FunctionType(objp, [_i8p])

        # define helper functions
        helper = {
            'objp': objp,
            'thp': thp,
            'objfunc': objfunc,
            'make_closure': ll.Function(
                module,
                ll.FunctionType(
                    objp,
                    [
                        thp,
                        ll.PointerType(ll.FunctionType(objp, [thp] * 2))
                    ]),
                'make_closure'),
            'apply_closure': ll.Function(
                module,
                ll.FunctionType(objp, [objp, thp]), 'apply_closure'),
            'make_thunk': ll.Function(
                module,
                ll.FunctionType(thp, [_i8p, ll.PointerType(objfunc)]),
                'make_thunk'),
            'thunk_ptr': ll.Function(
                module, ll.FunctionType(thp, []), 'thunk_ptr'),
            'fill_thunk': ll.Function(
                module,
                ll.FunctionType(_void, [thp, _i8p, ll.PointerType(objfunc)]),
                'fill_thunk'),
            'wrap_thunk': ll.Function(
                module, ll.FunctionType(thp, [_i8p]), 'wrap_thunk'),
            'eval_thunk': ll.Function(
                module, ll.FunctionType(objp, [thp]), 'eval_thunk'),
            'malloc': ll.Function(
                module, ll.FunctionType(_i8p, [_i32]), 'malloc'),
            'number': ll.Function(
                module, ll.FunctionType(thp, [_i64]), 'number'),
            'make_object': ll.Function(
                module, ll.FunctionType(objp, [_i8, _i64]), 'make_object'),
            'obj_val': ll.Function(
                module, ll.FunctionType(_i64, [objp]), 'obj_val')
        }

        # define all global methods and constants

        def glob_const(llvm_name):
            # reference pre-defined function
            return ll.GlobalVariable(module, thtype, llvm_name)


        def glob_func(llvm_name, ret_type, arg_types, type_int):
            funtype = ll.FunctionType(ret_type, arg_types)

            # reference pre-defined internal function
            internal = ll.Function(module, funtype, '%s_intern' % llvm_name)

            # create function that evals thunks to correct type
            func_ptr = ll.Function(
                module, ll.FunctionType(objp, [thp] * len(arg_types)),
                '%s_ptr' % llvm_name)
            func_ptr.linkage = 'private'
            builder = ll.IRBuilder(func_ptr.append_basic_block())

            # evaluate and cast arguments to right type
            arg_vals = []
            for arg, arg_type in zip(func_ptr.args, arg_types):
                obj_ptr = builder.call(helper['eval_thunk'], [arg], 'obj_ptr')
                val = builder.call(helper['obj_val'], [obj_ptr], 'val')
                val_cast = builder.trunc(val, arg_type, 'val_cast')
                arg_vals.append(val)

            # get result and convert back to object
            res = builder.call(internal, arg_vals, name='res')
            res_cast = builder.zext(res, _i64)
            obj = builder.call(
                helper['make_object'], [ll.Constant(_i8, type_int), res_cast],
                'obj')
            builder.ret(obj)

            # create function that makes closure for first argument
            func = ll.Function(
                module,
                ll.FunctionType(objp, [thp, thp]), '%s_closure' % llvm_name)
            func.linkage = 'linkonce_odr'
            func.args[0].name = 'env_null'
            func.args[1].name = 'arg'
            builder_ = ll.IRBuilder(func.append_basic_block())
            res = builder_.call(
                helper['make_closure'],
                [func.args[1], func_ptr], name='res')
            builder_.ret(res)

            # finally, access external definition of thunk
            return ll.GlobalVariable(module, thtype, llvm_name)

        env = {
            'True': glob_const('true'),
            'False': glob_const('false'),
            '+': glob_func('add', _i64, [_i64, _i64], 0),
            '-': glob_func('sub', _i64, [_i64, _i64], 0),
            '*': glob_func('mul', _i64, [_i64, _i64], 0),
            '/': glob_func('div', _i64, [_i64, _i64], 0),
            'mod': glob_func('mod', _i64, [_i64, _i64], 0),
            'pow': glob_func('pow', _i64, [_i64, _i64], 0),
            '==': glob_func('eq', _bool, [_i64, _i64], 1),
            '<=': glob_func('le', _bool, [_i64, _i64], 1)
        }

        # create main function
        main = ll.Function(module, ll.FunctionType(objp, []), 'main')
        builder = ll.IRBuilder(main.append_basic_block('entry'))

        # generate code
        thunk_ptr = self.body.gen_llvm(module, helper, builder, env)
        res_ptr = builder.call(
            helper['eval_thunk'], [thunk_ptr], name='res_ptr')
        builder.ret(res_ptr)

        # parse assembly
        llmod = llvm.parse_assembly(str(module))

        return llmod

    def wrap_import(self, imp):
        return Script([ModWrapper([Identifier(imp, False), self.body])])


class ModWrapper(Token):

    @property
    def name(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _gen_python(self):
        imports = (
            '_m = imp.load_source(\'%s\', \'%s\')\n'
            'for k, v in _m._result().value.iteritems():\n'
            '    globals()[k + \'_\'] = v\n'
        ) % (self.name.value,
             os.path.join(star_path.cache_dir, self.name.value + '.py'))
        return '%s\n%s' % (imports, self.body.gen_python())

    def gen_llvm(self, module, helper, builder, env):
        return self.body.gen_llvm(module, helper, builder, env)


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

    def free_identifiers(self):
        return set()


class Identifier(Terminator):
    def __init__(self, value, is_infix):
        Terminator.__init__(self, value)
        self._is_infix = is_infix

    @property
    def is_infix(self):
        return self._is_infix

    def python_name(self, is_attr=False):
        convert = {
            '.': 'f', '+': 'p', '-': 's', '*': 'a', '/': 'd', '=': 'e',
            '<': 'l', '>': 'g', '?': 'q', ':': 'c', '@': 't', '!': 'x',
            '$': 'o', '&': 'n', '|': 'r'
        }

        if any(x in self.value for x in convert.keys()):
            name = ''.join([convert.get(c, c) for c in self.value]) + '_'
        else:
            name = self.value

        if not is_attr:
            name += '_'
        return name

    def _gen_python(self):
        return 'return %s' % self.python_name()

    def free_identifiers(self):
        return set([self.value])

    def gen_llvm(self, module, helper, builder, env):
        return env[self.value]


class Number(Terminator):
    def _gen_python(self):
        return 'return star_type.Number(%s)' % self.value

    def gen_llvm(self, module, helper, builder, env):
        return builder.call(
            helper['number'], [ll.Constant(_i64, int(self.value))])


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
        return (
            'def _f%s():\n%s\ndef _f%s():\n%s\n_t%s = Thunk(_f%s)\n'
            'return lambda: trampoline(_f%s)(_t%s)' % (
                i1, self.operand.gen_python(True),
                i2, self.operator.gen_python(True), i1, i1, i2, i1))

    def gen_llvm(self, module, helper, builder, env):
        # create function to evaluate this expression
        fbuilder, new_env, thunk = _nest_function(
            module, helper, builder, env, self.free_identifiers())

        optor = self.operator.gen_llvm(module, helper, fbuilder, new_env)
        opand = self.operand.gen_llvm(module, helper, fbuilder, new_env)
        optor_val = fbuilder.call(
            helper['eval_thunk'], [optor], name='operator')
        res = fbuilder.call(
            helper['apply_closure'], [optor_val, opand], tail=True, name='res')
        fbuilder.ret(res)

        return thunk


class EmptyList(EmptyToken):

    def _gen_python(self):
        return 'return star_type.empty_list'


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
                '    return c__()(_t%s)(_t%s)\n'
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

    def gen_llvm(self, module, helper, builder, env):
        func = builder.function
        pred = self.predicate.gen_llvm(module, helper, builder, env)

        if_con = func.append_basic_block('if.con')
        if_alt = func.append_basic_block('if.alt')
        if_end = func.append_basic_block('if.end')

        pred_ptr = builder.call(helper['eval_thunk'], [pred], name='pred_ptr')
        pred_cast = builder.bitcast(pred_ptr, helper['objp'], name='pred_cast')
        pred_val = builder.call(helper['obj_val'], [pred_cast], 'pred')
        pred_bool = builder.trunc(pred_val, _bool, 'pred_bool')
        builder.cbranch(pred_bool, if_con, if_alt)

        builder.position_at_start(if_con)
        con = self.consequent.gen_llvm(module, helper, builder, env)
        builder.branch(if_end)

        builder.position_at_start(if_alt)
        alt = self.alternative.gen_llvm(module, helper, builder, env)
        builder.branch(if_end)

        builder.position_at_start(if_end)
        phi = builder.phi(helper['thp'], 'my_phi')
        phi.incomings = [(con, if_con), (alt, if_alt)]

        return phi


class Let(Token):

    @property
    def bindings(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def _gen_python(self):
        return '%s\n%s' % (self.bindings.gen_python(), self.body.gen_python())

    def free_identifiers(self):
        ids = Token.free_identifiers(self)
        # remove any identifiers that are bound here
        binds = set(i.value for i in chain(*[
            bind.bound_identifiers for bind in self.bindings.elements]))
        return ids - binds

    def gen_llvm(self, module, helper, builder, env):
        # get new bindings environment
        new_env = self.bindings.gen_llvm_env(module, helper, builder, env)
        return self.body.gen_llvm(module, helper, builder, new_env)


class Bindings(Token):

    @property
    def elements(self):
        return self._value

    def _gen_python(self):
        return '\n'.join([e.gen_python() for e in self.elements])

    def gen_llvm_env(self, module, helper, builder, env):
        # first build the environment...
        new_env = dict(env)
        thunks = []
        for elem in self.elements:
            thunk = elem.get_llvm_ref(module, helper, builder, new_env)
            new_env[elem.identifier.value] = thunk
            thunks.append(thunk)

        # ...then use the new environment for each binding!
        for elem, thunk in zip(self.elements, thunks):
            elem.gen_llvm_ref(module, helper, builder, new_env, thunk)

        return new_env


class Binding(Token):

    @property
    def identifier(self):
        return self._value[0]

    @property
    def bound_identifiers(self):
        return [self.identifier]

    @property
    def body(self):
        return self._value[1]

    def _gen_python(self):
        i = _get_id()
        return 'def _f%s():\n%s\n%s = Thunk(_f%s)' % (
            i, self.body.gen_python(True), self.identifier.python_name(), i)

    def free_identifiers(self):
        return self.body.free_identifiers()


    def get_llvm_ref(self, module, helper, builder, env):
        # call to get a reference to this binding before it is generated
        # this is important for recursive definitions
        return builder.call(helper['thunk_ptr'], [], name=self.identifier.value)


    def gen_llvm_ref(self, module, helper, builder, env, ref):
        # generate LLVM code, filling the referred thunk
        fbuilder, new_env, thunk = _nest_function(
            module, helper, builder, env, self.body.free_identifiers(), ref)
        bthunk = self.body.gen_llvm(module, helper, fbuilder, new_env)
        res = fbuilder.call(helper['eval_thunk'], [bthunk], name='res')
        fbuilder.ret(res)


class Enum(Token):
    @property
    def identifiers(self):
        return self._value

    @property
    def bound_identifiers(self):
        return list(self.identifiers)

    def _gen_python(self):
        names = [i.python_name() for i in self.identifiers]
        return '\n'.join('%s = star_type.Enum(\'%s\', %s)' % (n, n, _get_id())
                         for n in names)

    def free_identifiers(self):
        return set()


class Lambda(Token):

    @property
    def parameter(self):
        return self._value[0]

    @property
    def body(self):
        return self._value[1]

    def free_identifiers(self):
        ids = self.body.free_identifiers()
        # remove bound parameter from free identifiers
        ids.remove(self.parameter.value)
        return ids

    def _gen_python(self):
        i = _get_id()
        return 'def _f%s(%s):\n%s\nreturn _f%s' % (
            i, self.parameter.python_name(), self.body.gen_python(True), i)


class Object(Token):
    @property
    def bindings(self):
        return self._value

    def _gen_python(self):
        names = [b.identifier.python_name(True) for b in self.bindings]
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
        return 'def _o%s():\n%s' % (self.identifier.python_name(True),
                                    self.body.gen_python(True))

    def free_identifiers(self):
        return self.body.free_identifiers()


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
        ) % (i, self.body.gen_python(True),
             i, self.attribute.python_name(True))

    def free_identifiers(self):
        return self.body.free_identifiers()


class Import(Token):

    @property
    def name(self):
        return self._value[0]

    def _gen_python(self):
        return 'return imp.load_source(\'%s\', \'%s\')._result()' % (
            self.name.value,
            os.path.join(star_path.cache_dir, self.name.value + '.py'))

    def free_identifiers(self):
        return set()


class Export(Token):

    @property
    def identifiers(self):
        return self._value

    def _gen_python(self):
        names = [(i.python_name(True), i.python_name())
                 for i in self.identifiers]
        return (
            'return star_type.Object({%s})'
        ) % ', '.join(['\'%s\': %s' % (an, mn) for an, mn in names])


class Strict(Token):

    def __init__(self, value):
        Token.__init__(self, value)
        self.lazy = False

    @property
    def body(self):
        return self._value[0]

    def _gen_python(self):
        return self.body.gen_python()
