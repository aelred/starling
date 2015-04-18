%thunk_inner = type {i8*, i8* (i8*)*}
%thunk = type {i1, i8*}
%closure = type {%thunk*, i8* (%thunk*, %thunk*)*}

declare i8* @malloc(i32)

; Make a new closure from an environment pointer and function
define linkonce_odr i8* @make_closure(%thunk* %env, i8* (%thunk*, %thunk*)* %fun) {
    %c1 = insertvalue %closure zeroinitializer, %thunk* %env, 0
    %c2 = insertvalue %closure %c1, i8* (%thunk*, %thunk*)* %fun, 1

    ; TODO - Make sure this size is always correct
    %c_ptr = call i8* @malloc(i32 16)
    %c_cast = bitcast i8* %c_ptr to %closure*
    store %closure %c2, %closure* %c_cast
    ret i8* %c_ptr
}

; Apply an argument to a closure
define linkonce_odr i8* @apply_closure(i8* %c_ptr, %thunk* %arg) {
    %c_cast = bitcast i8* %c_ptr to %closure*
    %c = load %closure* %c_cast
    %env = extractvalue %closure %c, 0
    %fun = extractvalue %closure %c, 1
    %res = call i8* %fun(%thunk* %env, %thunk* %arg)
    ret i8* %res
}

; Make a thunk
define linkonce_odr %thunk* @make_thunk(i8* %env, i8* (i8*)* %fun) {
    %ti1 = insertvalue %thunk_inner zeroinitializer, i8* %env, 0
    %ti2 = insertvalue %thunk_inner %ti1, i8* (i8*)* %fun, 1

    ; TODO - Make sure this size is always correct
    %ti_ptr = call i8* @malloc(i32 16)
    %ti_cast = bitcast i8* %ti_ptr to %thunk_inner*
    store %thunk_inner %ti2, %thunk_inner* %ti_cast

    %t = insertvalue %thunk {i1 false, i8* null}, i8* %ti_ptr, 1

    ; TODO - Make sure this size is always correct
    %t_ptr = call i8* @malloc(i32 16)
    %t_cast = bitcast i8* %t_ptr to %thunk*
    store %thunk %t, %thunk* %t_cast
    ret %thunk* %t_cast
}

; Make a pre-evaluated thunk
define linkonce_odr %thunk* @wrap_thunk(i8* %val) {
    %t = insertvalue %thunk {i1 true, i8* null}, i8* %val, 1

    ; TODO - Make sure this size is always correct
    %t_ptr = call i8* @malloc(i32 16)
    %t_cast = bitcast i8* %t_ptr to %thunk*
    store %thunk %t, %thunk* %t_cast
    ret %thunk* %t_cast
}

; Evaluate a thunk
define linkonce_odr i8* @eval_thunk(%thunk* %t_ptr) {
entry:
    %t = load %thunk* %t_ptr
    %evald = extractvalue %thunk %t, 0
    %val = extractvalue %thunk %t, 1
    br i1 %evald, label %return_val, label %evaluate
evaluate:
    %tin_cast = bitcast i8* %val to %thunk_inner*
    %tin = load %thunk_inner* %tin_cast
    %env = extractvalue %thunk_inner %tin, 0
    %fun = extractvalue %thunk_inner %tin, 1
    %res = call i8* %fun(i8* %env)
    %t_new = insertvalue %thunk {i1 true, i8* null}, i8* %res, 1
    store %thunk %t_new, %thunk* %t_ptr
    ret i8* %res
return_val:
    ret i8* %val
}

; Constant True
@true_intern = private unnamed_addr constant i1 true
@true = linkonce_odr constant %thunk {i1 true, i8* bitcast (i1* @true_intern to i8*)}

; Constant False
@false_intern = private unnamed_addr constant i1 false
@false = linkonce_odr constant %thunk {i1 true, i8* bitcast (i1* @false_intern to i8*)}

; Addition function
define linkonce_odr i32 @add_intern(i32 %x, i32 %y) {
    %res = add i32 %x, %y
    ret i32 %res
}

declare i8* @add_closure(%thunk*, %thunk*)
@add_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @add_closure}
@add = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @add_null to i8*)}

; Subtraction function
define linkonce_odr i32 @sub_intern(i32 %x, i32 %y) {
    %res = sub i32 %x, %y
    ret i32 %res
}

declare i8* @sub_closure(%thunk*, %thunk*)
@sub_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @sub_closure}
@sub = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @sub_null to i8*)}

; Multiplication function
define linkonce_odr i32 @mul_intern(i32 %x, i32 %y) {
    %res = mul i32 %x, %y
    ret i32 %res
}

declare i8* @mul_closure(%thunk*, %thunk*)
@mul_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @mul_closure}
@mul = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @mul_null to i8*)}

; Division function
define linkonce_odr i32 @div_intern(i32 %x, i32 %y) {
    %res = sdiv i32 %x, %y
    ret i32 %res
}

declare i8* @div_closure(%thunk*, %thunk*)
@div_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @div_closure}
@div = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @div_null to i8*)}

; Modulo function
define linkonce_odr i32 @mod_intern(i32 %x, i32 %y) {
    %rem = urem i32 %x, %y

    ; flip sign if dividand is negative
    %is_pos = icmp sge i32 %y, 0
    %neg_rem = sub i32 0, %rem
    %res = select i1 %is_pos, i32 %rem, i32 %neg_rem
    ret i32 %res
}

declare i8* @mod_closure(%thunk*, %thunk*)
@mod_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @mod_closure}
@mod = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @mod_null to i8*)}

; Power function
define linkonce_odr i32 @pow_intern(i32 %b, i32 %e) {
entry:
    br label %cond
cond:
    %res = phi i32 [1, %entry], [%new_res, %shift]
    %exp = phi i32 [%e, %entry], [%new_exp, %shift]
    %base = phi i32 [%b, %entry], [%new_base, %shift]
    %cmp = icmp eq i32 %exp, 0
    br i1 %cmp, label %end, label %loop
loop:
    %last_dig = and i32 %exp, 1
    %odd = icmp eq i32 %last_dig, 1
    br i1 %odd, label %increase, label %shift
increase:
    %incr_res = mul i32 %res, %base
    br label %shift
shift:
    %new_res = phi i32 [%res, %loop], [%incr_res, %increase]
    %new_exp = lshr i32 %exp, 1
    %new_base = mul i32 %base, %base
    br label %cond
end:
    ret i32 %res
}

declare i8* @pow_closure(%thunk*, %thunk*)
@pow_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @pow_closure}
@pow = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @pow_null to i8*)}

; Equality function
define linkonce_odr i1 @eq_intern(i32 %x, i32 %y) {
    %res = icmp eq i32 %x, %y
    ret i1 %res
}

declare i8* @eq_closure(%thunk*, %thunk*)
@eq_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @eq_closure}
@eq = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @eq_null to i8*)}

; Less-than-or-equal function
define linkonce_odr i1 @le_intern(i32 %x, i32 %y) {
    %res = icmp sle i32 %x, %y
    ret i1 %res
}

declare i8* @le_closure(%thunk*, %thunk*)
@le_null = private constant %closure {%thunk* null, i8* (%thunk*, %thunk*)* @le_closure}
@le = linkonce_odr constant %thunk {i1 true, i8* bitcast (%closure* @le_null to i8*)}
