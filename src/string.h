#ifndef STRING_H__
#define STRING_H__

typedef struct {
    char *elems;
    int capacity;
    int size;
} string;

string *string_new(void);

void string_push(string *s, char c);

void string_append(string *, const char *format, ...);

char string_get(string *, int);

void string_free(string *);

#endif
