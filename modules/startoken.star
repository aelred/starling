let

# terminals
enum let_ in_ if_ then_ else_ enum_ arrow comma dot import_ export_ equals,
enum lpar rpar llist rlist lobj robj,
enum prefix_id infix_id bool number string char,

terminals = [
    let_, in_, if_, then_, else_, enum_, arrow, comma, dot, import_,
    export_, equals, lpar, rpar, llist, rlist, lobj, robj, prefix_id,
    infix_id, bool, number, string, char
],

# non-terminals
enum apply lambda let_expr bindings binding list enum_expr object getter,
enum part_getter tuple in 

export

let_ in_ if_ then_ else_ enum_ arrow comma dot equals import_ export_
lpar rpar llist rlist lobj robj
prefix_id infix_id bool string char number

terminals

apply lambda let_expr bindings binding list enum_expr object getter 
part_getter tuple
