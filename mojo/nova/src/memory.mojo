# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Memory."""

from algorithm import vectorize


@always_inline
fn _init[T: DefaultableValue](dst: UnsafePointer[T], count: Int):
    var offset = 0
    while offset < count:
        _move(dst + offset, T())
        offset += 1

@always_inline
fn _init[own: Bool, T: Value](dst: UnsafePointer[T], src: UnsafePointer[T]):
    @parameter
    if own:
        _move(dst, src)
    else:
        _copy(dst, src)

@always_inline
fn _copy[T: Copyable](ptr: UnsafePointer[T], value: T):
    __get_address_as_uninit_lvalue(ptr.address) = value

@always_inline
fn _copy[T: Copyable](dst: UnsafePointer[T], src: UnsafePointer[T]):
    _copy(dst, src[])

@always_inline
fn _copy[T: Copyable](dst: UnsafePointer[T], src: UnsafePointer[T], count: Int):
    var offset = 0
    while offset < count:
        _copy(dst + offset, src + offset)
        offset += 1

@always_inline
fn _copy[T: Value](dst: UnsafePointer[T], owned src: ArrayIter[T, _, _, _]):
    var offset = 0
    while len(src) > 0:
        _copy(dst + offset, src.__next__()[])
        offset += 1

@always_inline
fn _move[T: Movable](ptr: UnsafePointer[T], owned value: T):
    __get_address_as_uninit_lvalue(ptr.address) = value^

@always_inline
fn _move[T: Movable](dst: UnsafePointer[T], src: UnsafePointer[T]):
    _move(dst, __get_address_as_owned_value(src.address))

@always_inline
fn _move[T: Movable](dst: UnsafePointer[T], src: UnsafePointer[T], count: Int):
    var offset = 0
    while offset < count:
        _move(dst + offset, src + offset)
        offset += 1

@always_inline
fn _take[T: Movable](ptr: UnsafePointer[T]) -> T:
    return __get_address_as_owned_value(ptr.address)

@always_inline
fn _del(ptr: UnsafePointer[_]):
    _ = __get_address_as_owned_value(ptr.address)

@always_inline
fn _del(ptr: UnsafePointer[_], count: Int):
    var offset = 0
    while offset < count:
        _del(ptr + offset)
        offset += 1

@always_inline
fn memclr[type: DType, //](ptr: UnsafePointer[Scalar[type], _], count: Int):
    memset(ptr, 0, count)

@always_inline
fn memset[type: DType, //](ptr: UnsafePointer[Scalar[type], _], value: Scalar[type], count: Int):
    @parameter
    fn _set[width: Int](offset: Int):
        simd_store[width](ptr, offset, value)
    vectorize[_set, simdwidthof[type]()](count)

@always_inline
fn memcpy[type: DType, //](dst: UnsafePointer[Scalar[type], _], src: UnsafePointer[Scalar[type], _], count: Int):
    @parameter
    fn _cpy[width: Int](offset: Int):
        simd_store[width](dst, offset, simd_load[width](src, offset))
    vectorize[_cpy, simdwidthof[type]()](count)

@always_inline
fn simd_load[type: DType, //, width: Int, /, *, alignment: Int = 1](ptr: UnsafePointer[Scalar[type], _], offset: Int) -> SIMD[type, width]:
    @parameter
    if type is DType.bool:
        return __mlir_op.`pop.load`[alignment = alignment.value]((ptr + offset).bitcast[SIMD[DType.uint8, width]]().address).cast[type]()
    else:
        return __mlir_op.`pop.load`[alignment = alignment.value]((ptr + offset).bitcast[SIMD[type, width]]().address)

@always_inline
fn simd_store[type: DType, //, width: Int, /, *, alignment: Int = 1](ptr: UnsafePointer[Scalar[type], _], offset: Int, value: SIMD[type, width]):
    @parameter
    if type is DType.bool:
        __mlir_op.`pop.store`[alignment = alignment.value](value.cast[DType.uint8](), (ptr + offset).bitcast[SIMD[DType.uint8, width]]().address)
    else:
        __mlir_op.`pop.store`[alignment = alignment.value](value, (ptr + offset).bitcast[SIMD[type, width]]().address)
