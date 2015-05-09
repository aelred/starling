; A memory manager with copying garbage collection

%thunk = type opaque
%lambda = type opaque
%elem = type opaque

; Start of in-use memory block
@memalloc = private unnamed_addr global i8* null
; End of in-use memory block
@memend = private unnamed_addr global i8* null
; Size of in-use memory block
@memsize = private unnamed_addr constant i64 1024

; Position in memory block to allocate new objects
@memptr = private unnamed_addr global i8* null

; The header of each allocation indicates the type being stored.
; A 'broken heart' indicates the allocation has been moved elsewhere.
; In this case, the body of the allocation will point to the new object.
; 0 = thunk, 1 = lambda, 2 = elem, 3 = env, 4 = broken heart
; The second value indicates the size.
%header = type {i8, i64}

; Linked list of root objects that are live. Each root node points to an
; address inside the in-use memory block.
%rootnode = type {i8*, %rootnode*}

; The size of the header
@header_size = private unnamed_addr constant i64 2

declare i8* @malloc(i64)
declare void @free(i8*)
declare void @llvm.memcpy.p0i8.p0i8.i64(i8*, i8*, i64, i32, i1)

define linkonce_odr void @ginit() {
  ; malloc the correct amount of memory
  %memsize = load i64* @memsize
  %alloc = call i8* @malloc(i64 %memsize)

  ; initialize start, end and current position in memory block
  store i8* %alloc, i8** @memalloc
  store i8* %alloc, i8** @memptr
  %memend = getelementptr i8* %alloc, i64 %memsize
  store i8* %memend, i8** @memend

  ret void
}

define private i8* @galloc(i64 %size, i8 %type, %rootnode* %roots) {
entry:
  ; Get positions of header and new address allocated
  %memptr = load i8** @memptr
  %header_size = load i64* @header_size

  ; Make sure there is enough space
  %offset = add i64 %size, %header_size
  %newptr = getelementptr i8* %memptr, i64 %offset
  %memend = load i8** @memend
  %full = icmp ugt i8* %newptr, %memend
  br i1 %full, label %collect, label %allocate

collect:
  ; Perform garbage collection here
  br label %allocate

allocate:
  ; Reserve this space
  store i8* %newptr, i8** @memptr

  ; Store type and size in header
  %header_ptr = bitcast i8* %memptr to %header*
  %type_ptr = getelementptr %header* %header_ptr, i32 0, i32 0
  %size_ptr = getelementptr %header* %header_ptr, i32 0, i32 1
  store i8 %type, i8* %type_ptr
  store i64 %size, i64* %size_ptr

  ; Get allocated space and create root node containing it
  %addr = getelementptr i8* %memptr, i64 %header_size
  ret i8* %addr
}

define private %rootnode @add_root(i8* %ptr, %rootnode* %root) {
  ; Create a new root node as the new head of roots list
  %r1 = insertvalue %rootnode zeroinitializer, i8* %ptr, 0
  %r2 = insertvalue %rootnode %r1, %rootnode* %root, 1
  ret %rootnode %r2
}

define private i8* @load_root(%rootnode* %root) {
  %rootptr = getelementptr %rootnode* %root, i32 0, i32 0
  %ptr = load i8** %rootptr
  ret i8* %ptr
}

define private void @collect(%rootnode* %roots) {
  ; Allocate a new memory space
  %memold = load i8** @memalloc
  call void @ginit()
  %memnew = load i8** @memalloc

  ; Copy live objects from memold to memnew

  ; Free old memory space
  call void @free(i8* %memold)
  ret void
}

define private void @copyroots(%rootnode* %roots) {
  ; Copy all root objects into new memory space
entry:
  br label %cond
cond:
  %rootptr = phi %rootnode* [%roots, %entry], [%nextroot, %loop]
  ; If root is null, exit (end of linked list)
  %cmp = icmp eq %rootnode* %rootptr, null
  br i1 %cmp, label %end, label %loop
loop:
  ; Copy the given root and return the next
  %root = load %rootnode* %rootptr
  %oldptr = extractvalue %rootnode %root, 0

  ; Copy the root to the new memory space
  %newptr = call i8* @copy(i8* %oldptr)

  ; Update root with new pointer
  %newroot = insertvalue %rootnode %root, i8* %newptr, 0
  store %rootnode %newroot, %rootnode* %rootptr
  %nextroot = extractvalue %rootnode %root, 1
  br label %cond
end:
  ret void
}

define private i8* @copy(i8* %oldptr) {
  ; Copy something from old memory space to new
entry:
  ; Get the header
  %header_size = load i64* @header_size
  %negheader = sub i64 0, %header_size
  %headptr = getelementptr i8* %oldptr, i64 %negheader
  %headcast = bitcast i8* %headptr to %header*

  ; Check type of header to decide behaviour
  %typeptr = getelementptr %header* %headcast, i32 0, i32 0
  %type = load i8* %typeptr
  %cmp = icmp eq i8 %type, 4
  br i1 %cmp, label %brokenheart, label %otherwise

brokenheart:
  ; Get new location of object
  %ptrptr = bitcast i8* %oldptr to i8**
  %ptr = load i8** %ptrptr
  ret i8* %ptr

otherwise:
  ; Allocate memory in new space
  %sizeptr = getelementptr %header* %headcast, i32 0, i32 1
  %size = load i64* %sizeptr
  %memptr = load i8** @memptr
  %offset = add i64 %size, %header_size
  %newmemptr = getelementptr i8* %memptr, i64 %offset
  store i8* %newmemptr, i8** @memptr

  %newptr = getelementptr i8* %memptr, i64 %header_size

  ; Copy data into new pointer
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %newmemptr, i8* %headptr, 
                                       i64 %offset, i32 0, i1 0)

  ; Write broken heart into old location
  store i8 4, i8* %typeptr
  %heart = bitcast i8* %oldptr to i8**
  store i8* %newptr, i8** %heart

  ret i8* %newptr
}

define linkonce_odr %thunk* @thunk_alloc(%rootnode* %roots) {
  %ptr = call i8* @galloc(i64 24, i8 0, %rootnode* %roots)
  %t = bitcast i8* %ptr to %thunk*
  ret %thunk* %t
}

define linkonce_odr %lambda* @lambda_alloc(%rootnode* %roots) {
  %ptr = call i8* @galloc(i64 16, i8 1, %rootnode* %roots)
  %l = bitcast i8* %ptr to %lambda*
  ret %lambda* %l
}

define linkonce_odr %elem* @elem_alloc(%rootnode* %roots) {
  %ptr = call i8* @galloc(i64 16, i8 2, %rootnode* %roots)
  %e = bitcast i8* %ptr to %elem*
  ret %elem* %e
}

define linkonce_odr i8* @env_alloc(i64 %size, %rootnode* %roots) {
  %env = call i8* @galloc(i64 %size, i8 3, %rootnode* %roots)
  ret i8* %env
}

define linkonce_odr %rootnode @thunk_root(%thunk* %t_ptr, %rootnode* %roots) {
  %cast = bitcast %thunk* %t_ptr to i8*
  %root = call %rootnode @add_root(i8* %cast, %rootnode* %roots)
  ret %rootnode %root
}

define linkonce_odr %rootnode @lambda_root(%lambda* %l_ptr, %rootnode* %roots) {
  %cast = bitcast %lambda* %l_ptr to i8*
  %root = call %rootnode @add_root(i8* %cast, %rootnode* %roots)
  ret %rootnode %root
}

define linkonce_odr %rootnode @elem_root(%elem* %e_ptr, %rootnode* %roots) {
  %cast = bitcast %elem* %e_ptr to i8*
  %root = call %rootnode @add_root(i8* %cast, %rootnode* %roots)
  ret %rootnode %root
}

define linkonce_odr %rootnode @env_root(i8* %env_ptr, %rootnode* %roots) {
  %root = call %rootnode @add_root(i8* %env_ptr, %rootnode* %roots)
  ret %rootnode %root
}

define linkonce_odr %thunk* @load_thunk_root(%rootnode* %root) {
  %ptr = call i8* @load_root(%rootnode* %root)
  %cast = bitcast i8* %ptr to %thunk*
  ret %thunk* %cast
}

define linkonce_odr %lambda* @load_lambda_root(%rootnode* %root) {
  %ptr = call i8* @load_root(%rootnode* %root)
  %cast = bitcast i8* %ptr to %lambda*
  ret %lambda* %cast
}

define linkonce_odr %elem* @load_elem_root(%rootnode* %root) {
  %ptr = call i8* @load_root(%rootnode* %root)
  %cast = bitcast i8* %ptr to %elem*
  ret %elem* %cast
}

define linkonce_odr i8* @load_env_root(%rootnode* %root) {
  %ptr = call i8* @load_root(%rootnode* %root)
  ret i8* %ptr
}
