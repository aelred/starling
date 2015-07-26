#include <assert.h>
#include "starling.h"

void test_eval() {
    assert(eval("1").value == 1);
    assert(eval("2*3").value == 6);
}

void test_object_str() {
    char **str;
    object_str((struct Object){10}, str);
    assert(*str == "10");
}

void test_starling() {
    test_eval();
    test_object_str();
}
