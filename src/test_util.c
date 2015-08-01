#include <assert.h>
#include "test.h"
#include "util.h"

static void test_is_empty(void) {
    assert(is_empty(""));
    assert(!is_empty("hello world\n"));
    assert(is_empty(" \n \t      \n\t\r"));
    assert(!is_empty(" #~"));
}

void test_util() {
    test_is_empty();
}
