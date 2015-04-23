%thunk_inner = type {i8*, %object* (i8*)*}
%thunk = type {i1, i8*}
%lambda = type {i8*, %object* (i8*, %thunk*)*}
%object = type {i8, i64}

declare i8* @malloc(i32)

; Make a new lambda from an environment pointer and function
define linkonce_odr %object* @make_lambda(i8* %env, %object* (i8*, %thunk*)* %fun) {
    %l1 = insertvalue %lambda zeroinitializer, i8* %env, 0
    %l2 = insertvalue %lambda %l1, %object* (i8*, %thunk*)* %fun, 1

    ; TODO - Make sure this size is always correct
    %l_ptr = call i8* @malloc(i32 16)
    %l_cast = bitcast i8* %l_ptr to %lambda*
    store %lambda %l2, %lambda* %l_cast

    %l_int = ptrtoint i8* %l_ptr to i64
    %obj = insertvalue %object {i8 2, i64 0}, i64 %l_int, 1
    %obj_ptr = call i8* @malloc(i32 16)
    %obj_cast = bitcast i8* %obj_ptr to %object*
    store %object %obj, %object* %obj_cast
    ret %object* %obj_cast
}

; Apply an argument to a lambda
define linkonce_odr %object* @apply_lambda(%object* %l_obj, %thunk* %arg) {
    %l_ptr = call i64 @obj_val(%object* %l_obj)
    %l_cast = inttoptr i64 %l_ptr to %lambda*
    %l = load %lambda* %l_cast
    %env = extractvalue %lambda %l, 0
    %fun = extractvalue %lambda %l, 1
    %res = call %object* %fun(i8* %env, %thunk* %arg)
    ret %object* %res
}

; Make a thunk
define linkonce_odr %thunk* @make_thunk(i8* %env, %object* (i8*)* %fun) {
    %t_ptr = call %thunk* @thunk_ptr()
    call void @fill_thunk(%thunk* %t_ptr, i8* %env, %object* (i8*)* %fun)
    ret %thunk* %t_ptr
}

; Generate a thunk pointer
define linkonce_odr %thunk* @thunk_ptr() {
    ; TODO - Make sure this size is always correct
    %t_ptr = call i8* @malloc(i32 16)
    %t_cast = bitcast i8* %t_ptr to %thunk*
    ret %thunk* %t_cast
}

; Fill an existing thunk pointer with something
define linkonce_odr void @fill_thunk(%thunk* %t_ptr, i8* %env, %object* (i8*)* %fun) {
    %ti1 = insertvalue %thunk_inner zeroinitializer, i8* %env, 0
    %ti2 = insertvalue %thunk_inner %ti1, %object* (i8*)* %fun, 1

    ; TODO - Make sure this size is always correct
    %ti_ptr = call i8* @malloc(i32 16)
    %ti_cast = bitcast i8* %ti_ptr to %thunk_inner*
    store %thunk_inner %ti2, %thunk_inner* %ti_cast

    %t = insertvalue %thunk {i1 false, i8* null}, i8* %ti_ptr, 1
    store %thunk %t, %thunk* %t_ptr
    ret void
}

; Make a pre-evaluated thunk
define linkonce_odr %thunk* @wrap_thunk(%object* %val) {
    %val_cast = bitcast %object* %val to i8*
    %t = insertvalue %thunk {i1 true, i8* null}, i8* %val_cast, 1

    ; TODO - Make sure this size is always correct
    %t_ptr = call i8* @malloc(i32 16)
    %t_cast = bitcast i8* %t_ptr to %thunk*
    store %thunk %t, %thunk* %t_cast
    ret %thunk* %t_cast
}

; Evaluate a thunk
define linkonce_odr %object* @eval_thunk(%thunk* %t_ptr) {
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
    %res = call %object* %fun(i8* %env)
    %res_cast = bitcast %object* %res to i8*
    %t_new = insertvalue %thunk {i1 true, i8* null}, i8* %res_cast, 1
    store %thunk %t_new, %thunk* %t_ptr
    ret %object* %res
return_val:
    %val_cast = bitcast i8* %val to %object*
    ret %object* %val_cast
}

define linkonce_odr %object* @make_object(i8 %type, i64 %val) {
    %o1 = insertvalue %object zeroinitializer, i8 %type, 0
    %o2 = insertvalue %object %o1, i64 %val, 1
    
    ; TODO - Make sure this size is always correct
    %o_ptr = call i8* @malloc(i32 16)
    %o_cast = bitcast i8* %o_ptr to %object*
    store %object %o2, %object* %o_cast
    ret %object* %o_cast
}

define linkonce_odr i64 @obj_val(%object* %obj) {
    %val_ptr = getelementptr %object* %obj, i32 0, i32 1
    %val = load i64* %val_ptr
    ret i64 %val
}

define linkonce_odr %thunk* @number(i64 %val) {
    %num_ptr = call %object* @make_object(i8 0, i64 %val)
    %t = call %thunk* @wrap_thunk(%object* %num_ptr)
    ret %thunk* %t
}

; Constant True
@true_intern = private unnamed_addr constant %object {i8 1, i64 1}
@true = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @true_intern to i8*)}

; Constant False
@false_intern = private unnamed_addr constant %object {i8 1, i64 0}
@false = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @false_intern to i8*)}

; Addition function
define linkonce_odr i64 @add_intern(i64 %x, i64 %y) {
    %res = add i64 %x, %y
    ret i64 %res
}

declare %object* @add_apply(i8*, %thunk*)
@add_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @add_apply}
@add_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @add_lambda to i64)}
@add = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @add_obj to i8*)}

; Subtraction function
define linkonce_odr i64 @sub_intern(i64 %x, i64 %y) {
    %res = sub i64 %x, %y
    ret i64 %res
}

declare %object* @sub_apply(i8*, %thunk*)
@sub_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @sub_apply}
@sub_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @sub_lambda to i64)}
@sub = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @sub_obj to i8*)}

; Multiplication function
define linkonce_odr i64 @mul_intern(i64 %x, i64 %y) {
    %res = mul i64 %x, %y
    ret i64 %res
}

declare %object* @mul_apply(i8*, %thunk*)
@mul_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @mul_apply}
@mul_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @mul_lambda to i64)}
@mul = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @mul_obj to i8*)}

; Division function
define linkonce_odr i64 @div_intern(i64 %x, i64 %y) {
    %res = sdiv i64 %x, %y
    ret i64 %res
}

declare %object* @div_apply(i8*, %thunk*)
@div_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @div_apply}
@div_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @div_lambda to i64)}
@div = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @div_obj to i8*)}

; Modulo function
define linkonce_odr i64 @mod_intern(i64 %x, i64 %y) {
    %rem = urem i64 %x, %y

    ; flip sign if dividand is negative
    %is_pos = icmp sge i64 %y, 0
    %neg_rem = sub i64 0, %rem
    %res = select i1 %is_pos, i64 %rem, i64 %neg_rem
    ret i64 %res
}

declare %object* @mod_apply(i8*, %thunk*)
@mod_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @mod_apply}
@mod_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @mod_lambda to i64)}
@mod = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @mod_obj to i8*)}

; Power function
define linkonce_odr i64 @pow_intern(i64 %b, i64 %e) {
entry:
    br label %cond
cond:
    %res = phi i64 [1, %entry], [%new_res, %shift]
    %exp = phi i64 [%e, %entry], [%new_exp, %shift]
    %base = phi i64 [%b, %entry], [%new_base, %shift]
    %cmp = icmp eq i64 %exp, 0
    br i1 %cmp, label %end, label %loop
loop:
    %last_dig = and i64 %exp, 1
    %odd = icmp eq i64 %last_dig, 1
    br i1 %odd, label %increase, label %shift
increase:
    %incr_res = mul i64 %res, %base
    br label %shift
shift:
    %new_res = phi i64 [%res, %loop], [%incr_res, %increase]
    %new_exp = lshr i64 %exp, 1
    %new_base = mul i64 %base, %base
    br label %cond
end:
    ret i64 %res
}

declare %object* @pow_apply(i8*, %thunk*)
@pow_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @pow_apply}
@pow_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @pow_lambda to i64)}
@pow = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @pow_obj to i8*)}

; Equality function
define linkonce_odr i1 @eq_intern(i64 %x, i64 %y) {
    %res = icmp eq i64 %x, %y
    ret i1 %res
}

declare %object* @eq_apply(i8*, %thunk*)
@eq_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @eq_apply}
@eq_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @eq_lambda to i64)}
@eq = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @eq_obj to i8*)}

; Less-than-or-equal function
define linkonce_odr i1 @le_intern(i64 %x, i64 %y) {
    %res = icmp sle i64 %x, %y
    ret i1 %res
}

declare %object* @le_apply(i8*, %thunk*)
@le_lambda = private constant %lambda {i8* null, %object* (i8*, %thunk*)* @le_apply}
@le_obj = private constant %object {i8 2, i64 ptrtoint (%lambda* @le_lambda to i64)}
@le = linkonce_odr constant %thunk {i1 true, i8* bitcast (%object* @le_obj to i8*)}
