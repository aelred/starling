%option noyywrap
%option nounput
%option never-interactive

%{
#define YY_NO_INPUT
#include <malloc.h>
#include <string.h>
#include "node.h"
#include "parser.h"

static char *strndup(const char *s, size_t n) {
    char *new = malloc(sizeof(char) * n);
    strcpy(new, s);
    return new;
}

static char *strdup(const char *s) {
    return strndup(s, strlen(s));
}
%}

digit  [0-9]
word [a-zA-Z_][a-zA-Z_0-9]*

%%
"("       { return LPAR;   }
")"       { return RPAR;   }
"["       { return LLIST;  }
"]"       { return RLIST;  }
"{"       { return LOBJ;   }
"}"       { return ROBJ;   }
"="       { return EQUALS; }
","       { return COMMA;  }
"."       { return DOT;    }
"->"      { return ARROW;  }

"let"     { return LET;    }
"in"      { return IN;     }
"if"      { return IF;     }
"then"    { return THEN;   }
"else"    { return ELSE;   }
"enum"    { return ENUM;   }
"import"  { return IMPORT; }
"export"  { return EXPORT; }

#.*$      ; // skip comments
[ \t\n\r] ; // skip whitespace

True      { yylval.intval=1; return BOOL; }
False     { yylval.intval=0; return BOOL; }
{digit}+  { yylval.intval=atoi(yytext); return INT; }
[-+*/=<>?:@!&|]+|and|or|mod|pow|has {
    yylval.strval=strdup(yytext); return INFIX;
}
{word}    { yylval.strval=strdup(yytext); return PREFIX;  }
\"(\\.|[^\"])*\" {
    int size = strlen(yytext);
    yylval.strval=strndup(yytext+1, size-2);
    return STRING;
}
'(\\(x\x\x|[0-7]{1,3}|[^x0-7])|[^\'])' {
    int size = strlen(yytext);
    yylval.strval=strndup(yytext+1, size-2);
    return CHAR;
}

. { printf("Unknown character '%c'\n", yytext[0]); return UNKNOWN; }

%%
