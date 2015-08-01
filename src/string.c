#include <stdarg.h>
#include <malloc.h>
#include <string.h>
#include "string.h"

static const int INIT_CAPACITY = 4;

string *string_new() {
    string *s = malloc(sizeof(string));
    s->capacity = INIT_CAPACITY;
    s->elems = malloc(sizeof(char) * INIT_CAPACITY);
    s->elems[0] = '\0';
    s->size = 1;
    return s;
}

static void resize(string *s) {
    s->capacity *= 2;
    s->elems = realloc(s->elems, sizeof(char) * s->capacity);
}

void string_push(string *s, char c) {
    if (s->capacity == 0) {
	s->capacity = INIT_CAPACITY;
	s->elems = malloc(sizeof(char) * s->capacity);
    }

    if (s->size == s->capacity) resize(s);

    s->elems[s->size-1] = c;
    s->elems[s->size] = '\0';
    s->size++;
}

void string_append(string *s, const char *format, ...) {
    va_list args;
    int n;
    int resized = 0;
    
    va_start(args, format);
    n = vsnprintf(s->elems + s->size-1, s->capacity - s->size, format, args);
    va_end(args);
    while (s->size + n >= s->capacity) {
	// Resize to fit whole string
	resize(s);
	resized = 1;
    }

    if (resized) {
	// Reprint string if necessary
	va_start(args, format);
	vsnprintf(s->elems + s->size-1, s->capacity - s->size, format, args);
	va_end(args);
    }

    s->size += n;
}

void string_free(string *s) {
    free(s->elems);
    free(s);
}
