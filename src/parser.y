%code provides {
int yyparse(void);
Node *parser_result;
const char *token_name(int token);
}

%code requires {
#include "node.h"
}

%union {
    int intval;
    char *strval;
    Node *node;
    vector *strlist;
    vector *bindlist;
    Bind *bind;
    vector *elemlist;
}

%code top {
#define YYDEBUG 1
#include <stdio.h>
#include <malloc.h>
#include <math.h>
#include "node.h"
#include "lexer.h"
}

%{
int yydebug = 0;

Node *parser_result;

static Node *cons(Node *, Node *);
static Node *binop(const char *, Node *, Node *);
static Node *unop(const char *, Node *);

void yyerror(const char *s);

static Bind *binding(char *name, Node *expr) {
    Bind *b = malloc(sizeof(Bind));
    b->name = name;
    b->expr = expr;
    return b;
}

static int enum_count;

static Bind *enum_binding(char *name) {
    Node *id = node(INT);
    id->intval = enum_count++;
    return binding(name, unop("__builtin_enum", id));
}

static void tuple_add(vector *binds, Node *expr) {
    int num = binds->size;
    char *name = malloc(sizeof(char) * (ceil(log10(num+1)) + 2));
    sprintf(name, "_%d", num);
    vector_push(binds, binding(name, expr));
}
%}

%initial-action {
enum_count = 0;
}

%token LPAR RPAR LLIST RLIST LOBJ ROBJ EQUALS COMMA DOT ARROW LET IN IF THEN
%token ELSE ENUM IMPORT EXPORT STRICT UNKNOWN
%token <intval> BOOL INT 
%token <strval> PREFIX INFIX STRING CHAR

%type <node> expr if strict export atom import parens let lambda lambda_inner
%type <node> list list_inner tuple object object_accessor partial_accessor
%type <node> prefix_apply infix_apply infix_partial apply
%type <strval> ident
%type <strlist> export_inner
%type <bindlist> let_inner let_binding enum enum_inner object_inner 
%type <bindlist> tuple_inner
%type <bind> object_bind

%token OBJECT LAMBDA APPLY ACCESSOR IDENT

%token-table

/* Use a GLR parser to handle lambdas.
 * e.g. 'x y -> x * y'
 * Before the '->' the parser doesn't know if this is an application of x to y
 * or a lambda declaration. The lambda may have any number of parameters, so
 * lookahead doesn't resolve the problem. The GLR parser will attempt both
 * parses.
 */
%glr-parser
%expect 3

%%

script: expr { parser_result = $1; }

expr:
  let
| lambda
| if
| export
| strict
| partial_accessor
| apply
| infix_partial

atom:
  import
| object
| object_accessor
| tuple
| INT { $$ = node(INT); $$->intval = $1; }
| BOOL { $$ = node(BOOL); $$->intval = $1; }
| CHAR { $$ = node(CHAR); $$->strval = $1; }
| STRING { $$ = node(STRING); $$->strval = $1; }
| ident { $$ = node(IDENT); $$->ident.name = $1; $$->ident.def = NULL; }
| parens
| list

ident:
  PREFIX
| LPAR INFIX RPAR { $$ = $2; }

apply:
  prefix_apply
| infix_apply
| atom

prefix_apply:
  apply atom {
      $$ = node(APPLY);
      $$->apply.optor = $1;
      $$->apply.opand = $2;
  }

/* Infix operators are left-associative. */
infix_apply:
  apply INFIX atom { $$ = binop($2, $1, $3); }

infix_partial:
  atom INFIX { $$ = unop($2, $1); }
| INFIX atom {
      $$ = node(LAMBDA);
      $$->lambda.param = "()";  // Definitely unused variable name
      Node *param = node(IDENT);
      param->ident.name = "()";
      param->ident.def = NULL;
      $$->lambda.expr = binop($1, param, $2);
  }

strict:
  STRICT expr { $$ = node(STRICT); $$->expr = $2; }

export:
  EXPORT export_inner { $$ = node(EXPORT); $$->elems = $2; }

export_inner:
  export_inner ident { $$ = $1; vector_push($$, $2); }
| ident { $$ = vector_new(); vector_push($$, $1); }

import:
  IMPORT ident { $$ = node(IMPORT); $$->strval = $2; }

if:
  IF expr THEN expr ELSE expr { 
      $$ = node(IF);
      $$->if_.pred = $2;
      $$->if_.cons = $4;
      $$->if_.alt = $6;
  }

tuple:
  LPAR tuple_inner COMMA expr RPAR {
      $$ = node(OBJECT);
      $$->elems = $2;
      tuple_add($$->elems, $4);
  }

tuple_inner:
  tuple_inner COMMA expr { $$ = $1; tuple_add($$, $3); }
| expr { $$ = vector_new(); tuple_add($$, $1); }

object_accessor:
  atom partial_accessor {
      $$ = node(APPLY);
      $$->apply.opand = $1;
      $$->apply.optor = $2;
  }

partial_accessor:
  DOT ident { $$ = node(ACCESSOR); $$->strval = $2; }

object:
  LOBJ object_inner comma_opt ROBJ { $$ = node(OBJECT); $$->elems = $2; }

object_inner:
  object_inner COMMA object_bind { $$ = $1; vector_push($$, $3); }
| object_bind { $$ = vector_new(); vector_push($$, $1); }

object_bind:
  ident EQUALS expr { $$ = binding($1, $3); }

lambda:
  lambda_inner

lambda_inner:
  ident lambda_inner { 
      $$ = node(LAMBDA);
      $$->lambda.param = $1;
      $$->lambda.expr = $2;
  }
| ident ARROW expr { 
      $$ = node(LAMBDA);
      $$->lambda.param = $1;
      $$->lambda.expr = $3;
  }

let:
  LET let_inner IN expr { 
      $$ = node(LET);
      $$->let.binds = $2;
      $$->let.expr = $4;
  }

let_inner:
  let_inner COMMA let_binding { $$ = $1; vector_join($$, $3); }
| let_binding { $$ = vector_new(); vector_join($$, $1); }

let_binding:
  ident EQUALS expr { $$ = vector_new(); vector_push($$, binding($1, $3)); }
| enum

enum:
  ENUM enum_inner { $$ = $2; }

enum_inner:
  enum_inner ident { $$ = $1; vector_push($$, enum_binding($2)); }
| ident { $$ = vector_new(); vector_push($$, enum_binding($1)); }

list:
  LLIST list_inner RLIST { $$ = $2; }
| LLIST RLIST { $$ = node(OBJECT); $$->elems = vector_new(); }

list_inner:
  expr COMMA list_inner { $$ = cons($1, $3); }
| expr {
      Node *obj = node(OBJECT);
      obj->elems = vector_new();
      $$ = cons($1, obj);
  }

parens:
  LPAR expr RPAR { $$ = $2; }

comma_opt:
  COMMA | /* empty */

%%

Node *cons(Node *elem, Node *list) {
    return binop(":", elem, list);
}

Node *binop(const char *name, Node *x, Node *y) {
    Node *part = unop(name, x);
    Node *app = node(APPLY);
    app->apply.optor = part;
    app->apply.opand = y;
    return app;
}

Node *unop(const char *name, Node *x) {
    Node *op = node(IDENT);
    op->ident.name = name;
    op->ident.def = NULL;
    Node *app = node(APPLY);
    app->apply.optor = op;
    app->apply.opand = x;
    return app;
}

void yyerror(const char *s) {
    printf("Parse error: %s\n", s);
}

const char *token_name(int token) {
    return yytname[yytranslate[token]];
}
