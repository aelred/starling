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

; The header of each allocation indicates the type being stored
; 0 = thunk, 1 = lambda, 2 = elem, 3 = env
%header = type {i8}

; The size of the header
@header_size = private unnamed_addr constant i64 1

declare i8* @malloc(i64)
declare void @free(i8*)

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

define private i8* @galloc(i64 %size, i8 %type) {
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

  ; Store type in header
  %header_ptr = bitcast i8* %memptr to %header*
  %type_ptr = getelementptr %header* %header_ptr, i32 0, i32 0
  store i8 %type, i8* %type_ptr

  ; Return allocated space
  %addr = getelementptr i8* %memptr, i64 %header_size
  ret i8* %addr
}

define private void @collect() {
  ; Allocate a new memory space
  %size = load i64* @memsize
  %memold = load i8** @memalloc
  call void @ginit()
  %memnew = load i8** @memalloc

  ; Copy live objects from memold to memnew

  ; Free old memory space
  call void @free(i8* %memold)
  ret void
}

define linkonce_odr %thunk* @thunk_alloc() {
  %ptr = call i8* @galloc(i64 24, i8 0)
  %t = bitcast i8* %ptr to %thunk*
  ret %thunk* %t
}

define linkonce_odr %lambda* @lambda_alloc() {
  %ptr = call i8* @galloc(i64 16, i8 1)
  %l = bitcast i8* %ptr to %lambda*
  ret %lambda* %l
}

define linkonce_odr %elem* @elem_alloc() {
  %ptr = call i8* @galloc(i64 16, i8 2)
  %l = bitcast i8* %ptr to %elem*
  ret %elem* %l
}

define linkonce_odr i8* @env_alloc(i64 %size) {
  %ptr = call i8* @galloc(i64 %size, i8 3)
  ret i8* %ptr
}
