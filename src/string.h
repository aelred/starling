#ifndef STRING_H__
#define STRING_H__

// A variable-length string of characters
typedef struct {
    char *elems;
    int capacity;
    int size;
} string;

// Return a new, empty string
string *string_new(void);

// Add a new element to the given string
void string_push(string *s, char c);

// Append a new, formatted string to the given string
void string_append(string *, const char *format, ...);

// Get the character at the given index
char string_get(string *, int);

// Free memory used by the given string
void string_free(string *);

#endif
