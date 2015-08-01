#ifndef VECTOR_H__
#define VECTOR_H__

typedef struct {
    void **elems;
    int capacity;
    int size;
} vector;

vector *vector_new(void);

void vector_push(vector *, void *);

void vector_join(vector *, vector *);

void *vector_get(vector *, int);

void vector_free(vector *);

#endif
