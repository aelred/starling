let
t = import startoken,

parser = import parser,
::= = parser.::=,
| = parser.|,

enum expr atom inner_apply ident inner_params inner_bindings expr_list,
enum let_elem obj_bindings ident_list,

grammar = parser.grammar expr t.terminals [
    # an expression is an evaluatable part that is made up of several atoms
    expr ::= [t.apply] | [atom] | [t.lambda] | [t.let_expr] | [t.if_expr],
    expr ::= [t.part_getter] | [t.export_expr],

    # an atom is an indivisible unit
    atom ::= [t.number] | [t.char] | [t.bool] | [ident] | [t.object],
    atom ::= [t.tuple] | [t.string] | [t.list] | [t.lpar, expr, t.rpar], 
    atom ::= [t.getter] | [t.import_expr],

    # an application is a sequence of atoms that will be applied together
    t.apply ::= [atom, inner_apply],
    inner_apply ::= [atom, inner_apply] | [atom],

    # a lambda expression is a single parameter and a body expression
    # lambdas can be chained together to create a curried function
    t.lambda ::= [ident, t.arrow, expr] | [ident, t.lambda],

    # a let expression is a list of bindings and a body expression
    t.let_expr ::= [t.let_, t.bindings, t.in_, expr],
    t.bindings ::= [inner_bindings],
    inner_bindings ::= [let_elem, t.comma, inner_bindings] | [let_elem],
    let_elem ::= [t.binding] | [t.enum_expr],
    t.binding ::= [ident, t.equals, expr],

    # an if-expression has a predicate, consequent and alternative
    t.if_expr ::= [t.if_, expr, t.then_, expr, t.else_, expr],

    # an enum is the keyword enum followed by a list of identifiers
    t.enum_expr ::= [t.enum_, ident_list],

    # an identifier is either prefix or infix
    ident ::= [t.prefix_id] | [t.infix_id],

    # an object contains some bindings
    t.object ::= [t.lobj, obj_bindings, t.robj] | [t.lobj, t.robj],
    obj_bindings ::= [t.binding, t.comma, obj_bindings] | [t.binding],

    # a tuple is a list of expressions in brackets
    # a tuple with only one expression must have a trailing comma
    t.tuple ::= [t.lpar, expr, t.comma, expr_list, t.rpar],
    t.tuple ::= [t.lpar, expr, t.comma, t.rpar],

    # a getter takes an expression and an object attribute identifier
    # a partially applied getter only gives the attribute identifier
    t.getter ::= [atom, t.dot, ident],
    t.part_getter ::= [t.dot, ident],

    # lists are just syntactic sugar for cons'ing elements together
    t.list ::= [t.llist, expr_list, t.rlist] | [t.llist, t.rlist],

    # an import is the import keyword followed by an identifier
    t.import_expr ::= [t.import_, ident],

    # an export is the export keyword followed by several # identifiers
    t.export_expr ::= [t.export_, ident_list],

    # a list of expressions, separated by commas
    expr_list ::= [expr, t.comma, expr_list] | [expr],
    # a list of identifiers with no separators
    ident_list ::= [ident, ident_list] | [ident]
],

# list of parse tree elements that should be removed from the final parse
suppress = [
    expr, atom, t.lpar, t.rpar, inner_apply, t.arrow, ident,
    inner_params, inner_bindings, t.equals, t.let_, t.comma, t.in_,
    t.llist, t.rlist, expr_list, ident_list, t.enum_, let_elem, obj_bindings,
    t.dot, t.lobj, t.robj, t.import_, t.export_, t.if_, t.then_, t.else_
],

parse = map (parser.suppress suppress) >> (parser.parse grammar)

in export parse
