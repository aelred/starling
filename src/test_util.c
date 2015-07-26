#include <assert.h>
#include "util.h"

void test_is_empty() {
    assert(is_empty(""));
    assert(!is_empty("hello world\n"));
    assert(is_empty(" \n \t      \n\t\r"));
    assert(!is_empty(" #~"));
}

void test_util() {
    test_is_empty();
}
