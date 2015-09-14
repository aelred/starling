#ifndef VECTOR_H__
#define VECTOR_H__

// A resizable vector
typedef struct {
    void **elems;
    int capacity;
    int size;
} vector;

// Create a new, empty vector
vector *vector_new(void);

// Push a new element onto the vector
void vector_push(vector *, void *);

// Pop the last element off the vector
void *vector_pop(vector *);

// Remove the element at the given index
void vector_remove(vector *, int);

// Append the second vector to the first
void vector_join(vector *, vector *);

// Get the element at the given index
void *vector_get(vector *, int);

// Free memory used by a vector
void vector_free(vector *);

#endif
