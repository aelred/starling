#include <malloc.h>
#include "vector.h"

static const int INIT_CAPACITY = 4;

vector *vector_new() {
    vector *v = malloc(sizeof(vector));
    v->elems = NULL;
    v->capacity = 0;
    v->size = 0;
    return v;
}

void vector_push(vector *v, void *elem) {
    if (v->capacity == 0) {
	v->capacity = INIT_CAPACITY;
	v->elems = malloc(sizeof(void *) * v->capacity);
    }

    if (v->size == v->capacity) {
	v->capacity *= 2;
	v->elems = realloc(v->elems, sizeof(void *) * v->capacity);
    }

    v->elems[v->size] = elem;
    v->size++;
}

void *vector_pop(vector *v) {
    v->size--;
    return v->elems[v->size];
}

void vector_remove(vector *v, int index) {
    // Move up all elements
    for (int i = index; i < v->size-1; i ++) {
	v->elems[i] = v->elems[i+1];
    }
    v->size--;
}

void vector_join(vector *v1, vector *v2) {
    int i;
    for (i=0; i < v2->size; i++) {
	vector_push(v1, vector_get(v2, i));
    }
}

void *vector_get(vector *v, int index) {
    return v->elems[index];
}

void vector_free(vector *v) {
    free(v->elems);
    free(v);
}
