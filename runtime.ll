; Thunks contain a bool indicating if they have been evaluated.
; If they have, the second argument is the evaluated result object,
; otherwise the second argument is an environment and the third is a function.
%thunk = type {i1, i8*, %elem* (i8*)*}
%lambda = type {i8*, %elem* (i8*, %thunk*, %rootnode*)*}
%elem = type {i8, i64}

declare %rootnode @thunk_alloc(%rootnode*)
declare %rootnode @lambda_alloc(%rootnode*)
declare %rootnode @elem_alloc(%rootnode*)

%rootnode = type opaque
declare %thunk* @load_thunk_root(%rootnode*)
declare %lambda* @load_lambda_root(%rootnode*)
declare %elem* @load_elem_root(%rootnode*)

; Make a new lambda from an environment pointer and function
define linkonce_odr %elem* @make_lambda(%rootnode* %env_root, %elem* (i8*, %thunk*, %rootnode*)* %fun, %rootnode* %root) {
    ; Allocate space for lambda pointer and put on roots
    %l_root = call %rootnode @lambda_alloc(%rootnode* %root)
    %l_stack = alloca %rootnode
    store %rootnode %l_root, %rootnode* %l_stack

    %e_ptr = call %elem* @elem_alloc(%rootnode* %l_root)

    ; Load lambda pointer from roots (it may have been moved after elem_alloc)
    %l_ptr = call %lambda* @load_lambda_root(%rootnode* %l_root)

    %env = call i8* @load_env_root(%rootnode* %env_root)
    %l1 = insertvalue %lambda zeroinitializer, i8* %env, 0
    %l2 = insertvalue %lambda %l1, %elem* (i8*, %thunk*, %rootnode*)* %fun, 1
    store %lambda %l2, %lambda* %l_ptr

    %l_int = ptrtoint %lambda* %l_ptr to i64
    %e = insertvalue %elem {i8 2, i64 0}, i64 %l_int, 1
    store %elem %e, %elem* %e_ptr

    ret %elem* %e_ptr
}

; Apply an argument to a lambda
define linkonce_odr %elem* @apply_lambda(%elem* %l_elem, %thunk* %arg, %rootnode* %root) {
    %l_ptr = call i64 @elem_val(%elem* %l_elem)
    %l_cast = inttoptr i64 %l_ptr to %lambda*
    %l = load %lambda* %l_cast
    %env = extractvalue %lambda %l, 0
    %fun = extractvalue %lambda %l, 1
    %res = call %elem* %fun(i8* %env, %thunk* %arg, %rootnode* %root)
    ret %elem* %res
}

; Make a thunk
define linkonce_odr %thunk* @make_thunk(%rootnode* %env_root, %elem* (i8*)* %fun, %rootnode* %root) {
    %t_root = call %rootnode @thunk_alloc(%rootnode* %root)
    %t_ptr = call %thunk* @load_thunk_root(%rootnode* %t_root)
    %env = call i8* @load_env_root(%rootnode* %env_root)
    call void @fill_thunk(%thunk* %t_ptr, i8* %env, %elem* (i8*)* %fun)
    ret %thunk* %t_ptr
}

; Fill an existing thunk pointer with something
define linkonce_odr void @fill_thunk(%thunk* %t_ptr, i8* %env, %elem* (i8*)* %fun) {
    %t1 = insertvalue %thunk {i1 false, i8* null, %elem* (i8*)* null}, i8* %env, 1
    %t2 = insertvalue %thunk %t1, %elem* (i8*)* %fun, 2
    store %thunk %t2, %thunk* %t_ptr
    ret void
}

; Make a pre-evaluated thunk
define linkonce_odr %thunk* @wrap_thunk(%elem** %val_stack) {
    %t_ptr = call %thunk* @thunk_alloc()

    %val = load %elem** %val_stack
    %val_cast = bitcast %elem* %val to i8*
    %t = insertvalue %thunk {i1 true, i8* null, %elem* (i8*)* null}, i8* %val_cast, 1
    store %thunk %t, %thunk* %t_ptr
    ret %thunk* %t_ptr
}

; Evaluate a thunk
define linkonce_odr %elem* @eval_thunk(%thunk* %t_ptr) {
entry:
    %t = load %thunk* %t_ptr
    %evald = extractvalue %thunk %t, 0
    %val = extractvalue %thunk %t, 1
    br i1 %evald, label %return_val, label %evaluate
evaluate:
    ; Put thunk on roots so it isn't garbage collected
    %t_stack = alloca %thunk*
    store %thunk* %t_ptr, %thunk** %t_stack
    %t_root = call %rootnode* @thunk_root(%thunk** %t_stack) 

    %fun = extractvalue %thunk %t, 2
    %res = call %elem* %fun(i8* %val)
    %res_cast = bitcast %elem* %res to i8*
    %t_new = insertvalue %thunk {i1 true, i8* null, %elem* (i8*)* null}, i8* %res_cast, 1

    ; Reload thunk pointer in case garbage collection moved pointer
    %t_ptr2 = load %thunk** %t_stack
    store %thunk %t_new, %thunk* %t_ptr2
    ret %elem* %res
return_val:
    %val_cast = bitcast i8* %val to %elem*
    ret %elem* %val_cast
}

define linkonce_odr %elem* @make_elem(i8 %type, i64 %val) {
    %e_ptr = call %elem* @elem_alloc()
    %o1 = insertvalue %elem zeroinitializer, i8 %type, 0
    %o2 = insertvalue %elem %o1, i64 %val, 1
    store %elem %o2, %elem* %e_ptr
    ret %elem* %e_ptr
}

define linkonce_odr i64 @elem_val(%elem* %e) {
    %val_ptr = getelementptr %elem* %e, i32 0, i32 1
    %val = load i64* %val_ptr
    ret i64 %val
}

define linkonce_odr %thunk* @number(i64 %val) {
    %num_ptr = call %elem* @make_elem(i8 0, i64 %val)
    %num_stack = alloca %elem*
    store %elem* %num_ptr, %elem** %num_stack
    %num_root = call %rootnode* @elem_root(%elem** %num_stack)
    %t = call %thunk* @wrap_thunk(%elem** %num_stack)
    ret %thunk* %t
}

; Constant True
@true_intern = private unnamed_addr constant %elem {i8 1, i64 1}
@true = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @true_intern to i8*), %elem* (i8*)* null}

; Constant False
@false_intern = private unnamed_addr constant %elem {i8 1, i64 0}
@false = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @false_intern to i8*), %elem* (i8*)* null}

; Addition function
define linkonce_odr i64 @add_intern(i64 %x, i64 %y) {
    %res = add i64 %x, %y
    ret i64 %res
}

declare %elem* @add_apply(i8*, %thunk*)
@add_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @add_apply}
@add_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @add_lambda to i64)}
@add = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @add_obj to i8*), %elem* (i8*)* null}

; Subtraction function
define linkonce_odr i64 @sub_intern(i64 %x, i64 %y) {
    %res = sub i64 %x, %y
    ret i64 %res
}

declare %elem* @sub_apply(i8*, %thunk*)
@sub_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @sub_apply}
@sub_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @sub_lambda to i64)}
@sub = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @sub_obj to i8*), %elem* (i8*)* null}

; Multiplication function
define linkonce_odr i64 @mul_intern(i64 %x, i64 %y) {
    %res = mul i64 %x, %y
    ret i64 %res
}

declare %elem* @mul_apply(i8*, %thunk*)
@mul_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @mul_apply}
@mul_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @mul_lambda to i64)}
@mul = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @mul_obj to i8*), %elem* (i8*)* null}

; Division function
define linkonce_odr i64 @div_intern(i64 %x, i64 %y) {
    %res = sdiv i64 %x, %y
    ret i64 %res
}

declare %elem* @div_apply(i8*, %thunk*)
@div_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @div_apply}
@div_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @div_lambda to i64)}
@div = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @div_obj to i8*), %elem* (i8*)* null}

; Modulo function
define linkonce_odr i64 @mod_intern(i64 %x, i64 %y) {
    %rem = urem i64 %x, %y

    ; flip sign if dividand is negative
    %is_pos = icmp sge i64 %y, 0
    %neg_rem = sub i64 0, %rem
    %res = select i1 %is_pos, i64 %rem, i64 %neg_rem
    ret i64 %res
}

declare %elem* @mod_apply(i8*, %thunk*)
@mod_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @mod_apply}
@mod_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @mod_lambda to i64)}
@mod = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @mod_obj to i8*), %elem* (i8*)* null}

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

declare %elem* @pow_apply(i8*, %thunk*)
@pow_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @pow_apply}
@pow_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @pow_lambda to i64)}
@pow = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @pow_obj to i8*), %elem* (i8*)* null}

; Equality function
define linkonce_odr i1 @eq_intern(i64 %x, i64 %y) {
    %res = icmp eq i64 %x, %y
    ret i1 %res
}

declare %elem* @eq_apply(i8*, %thunk*)
@eq_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @eq_apply}
@eq_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @eq_lambda to i64)}
@eq = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @eq_obj to i8*), %elem* (i8*)* null}

; Less-than-or-equal function
define linkonce_odr i1 @le_intern(i64 %x, i64 %y) {
    %res = icmp sle i64 %x, %y
    ret i1 %res
}

declare %elem* @le_apply(i8*, %thunk*)
@le_lambda = private constant %lambda {i8* null, %elem* (i8*, %thunk*)* @le_apply}
@le_obj = private constant %elem {i8 2, i64 ptrtoint (%lambda* @le_lambda to i64)}
@le = linkonce_odr constant %thunk {i1 true, i8* bitcast (%elem* @le_obj to i8*), %elem* (i8*)* null}
