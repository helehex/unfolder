# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Vector."""

from ..memory import memclr, memset, memcpy, simd_store, simd_load
from ..algorithm import vectorize_stoping
from algorithm import vectorize


# +----------------------------------------------------------------------------------------------+ #
# | Vector
# +----------------------------------------------------------------------------------------------+ #
#
#
struct Vector[type: DType, bnd: SpanBound = SpanBound.Lap, fmt: ArrayFormat = "[, ]", spc: AddressSpace = AddressSpace.GENERIC](Formattable, Sized, Value):
    """A heap allocated vector.

    Parameters:
        type: The data type of elements in the vector.
        bnd: The boundary condition to use with subscripts.
        fmt: The default format used when printing the vector.
        spc: The address space of the vector.
    """

    # +------< Data >------+ #
    #
    var _data: UnsafePointer[Scalar[type], spc]
    var _size: Int

    # +------( Lifecycle )------+ #
    #
    @always_inline("nodebug")
    fn __init__(inout self):
        """Creates a null vector with zero size."""
        self._data = UnsafePointer[Scalar[type], spc]()
        self._size = 0

    @always_inline("nodebug")
    fn __init__[clear: Bool = True](inout self, *, size: Int):
        """Creates a new vector and fills it with zero."""
        self._data = UnsafePointer[Scalar[type], spc].alloc(size)
        self._size = size
        @parameter
        if clear:
            self.clear()

    @always_inline("nodebug")
    fn __init__[width: Int = 1](inout self, *values: SIMD[type, width]):
        """Creates a new vector with the given values."""
        self.__init__[False](size = len(values) * width)
        for idx in range(len(values)):
            self.unsafe_set[width](idx * width, values[idx])

    @always_inline("nodebug")
    fn __init__[width: Int = 1](inout self, *values: SIMD[type, width], size: Int):
        """Creates a new vector with the given values."""
        self.__init__[False](size = size)
        @parameter
        @always_inline("nodebug")
        fn _set[_width: Int](idx: Int):
            @parameter
            if width != 1 and _width == 1:
                self.unsafe_set[1](idx, values[(idx // width) % len(values)][idx % width])
            else:
                self.unsafe_set[width](idx, values[(idx // width) % len(values)])
        vectorize[_set, width](size)

    @always_inline("nodebug")
    fn __init__(inout self, *values: Vector[type, _, _, _]):
        """Creates a new vector by joining existing vectors."""
        var size = 0
        for value in values:
            size += len(value[])
        self.__init__[False](size = size)
        var data = self._data
        for value in values:
            memcpy(data, value[]._data, value[]._size)
            data += value[]._size    

    @always_inline("nodebug")
    fn __init__(inout self, *values: Vector[type, _, _, _], size: Int):
        """Creates a new vector by joining existing vectors."""
        self.__init__[False](size = size)
        var idx = 0
        while True:
            for value in values:
                memcpy(self._data + idx, value[]._data, min(value[]._size, size - idx))
                idx += value[]._size
                if idx >= size:
                    return     

    @always_inline("nodebug")
    fn __copyinit__(inout self, other: Self):
        """Copy the data from another vector into this one."""
        self = Self(other) if other._data else Self()

    @always_inline("nodebug")
    fn __moveinit__(inout self, owned other: Self):
        """Move the data from another vector into this one."""
        self._data = other._data
        self._size = other._size

    @always_inline("nodebug")
    fn __del__(owned self):
        """Delete the data from this vector."""
        if self._data:
            self._data.free()

    # +------( Subscript )------+ #
    #
    alias _default_alignment = alignof[type]() if triple_is_nvidia_cuda() else 1

    @always_inline("nodebug")
    fn __getitem__[width: Int = 1, bnd: SpanBound = bnd](self, owned idx: Int) -> SIMD[type, width]:
        @parameter
        if width != 1 and bnd != SpanBound.Unsafe:
            if idx + width > self._size:
                var result = SIMD[type, width]()
                @parameter
                for lane in range(width):
                    var idx2 = idx + lane
                    bnd.adjust(idx2, self._size)
                    result[lane] = self.unsafe_get[1](idx2)
                return result
        bnd.adjust(idx, self._size)
        return self.unsafe_get[width](idx)

    @always_inline("nodebug")
    fn unsafe_get[width: Int = 1](self, idx: Int) -> SIMD[type, width]:
        return simd_load[width](self._data, idx)

    @always_inline("nodebug")
    fn __setitem__[width: Int = 1, bnd: SpanBound = bnd](inout self, owned idx: Int, value: SIMD[type, width]):
        @parameter
        if width != 1 and bnd != SpanBound.Unsafe:
            if idx + width > self._size:
                @parameter
                for lane in range(width):
                    var idx2 = idx + lane
                    bnd.adjust(idx2, self._size)
                    self.unsafe_set[1](idx2, value[lane])
                return
        bnd.adjust(idx, self._size)
        self.unsafe_set[width](idx, value)

    @always_inline("nodebug")
    fn unsafe_set[width: Int = 1](inout self, idx: Int, value: SIMD[type, width]):
        simd_store[width](self._data, idx, value)

    @always_inline("nodebug")
    fn __getitem__[bnd: SpanBound = bnd](ref[_]self, owned slice: Slice) -> VectorIter[type, bnd, fmt, __lifetime_of(self), spc]:
        bnd.adjust(slice, self._size)
        return VectorIter[type, bnd, fmt, __lifetime_of(self), spc](self._data, slice)

    @always_inline("nodebug")
    fn __setitem__(inout self, owned slice: Slice, value: VectorIter[type, _, _, _, _]):
        var sliced_self = self[slice]
        for idx in range(min(len(sliced_self), len(value))):
            self[idx] = value[idx]

    @always_inline("nodebug")
    fn clear(self):
        memclr(self._data, self._size)

    @always_inline("nodebug")
    fn fill(self, value: Scalar[type]):
        memset(self._data, value, self._size)

    # +------( Iterate )------+ #
    #
    @always_inline("nodebug")
    fn __iter__(ref[_]self) -> VectorIter[type, bnd, fmt, __lifetime_of(self), spc]:
        return self[:]

    @always_inline("nodebug")
    fn __reversed__(ref[_]self) -> VectorIter[type, bnd, fmt, __lifetime_of(self), spc]:
        return self[::-1]

    # +------( Format )------+ #
    #
    @always_inline("nodebug")
    fn __str__[fmt: ArrayFormat = fmt](self) -> String:
        return self[:].__str__[fmt]()

    @always_inline("nodebug")
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter):
        return self[:].format_to[fmt](writer)

    @always_inline("nodebug")
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter, align: Int):
        return self[:].format_to[fmt](writer, align)

    # +------( Operations )------+ #
    #
    @always_inline("nodebug")
    fn __len__(self) -> Int:
        return self._size

    @always_inline("nodebug")
    fn __is__(self, rhs: Self) -> Bool:
        return self._data == rhs._data

    @always_inline("nodebug")
    fn __isnot__(self, other: Self) -> Bool:
        return self._data != other._data

    @always_inline("nodebug")
    fn __contains__(self, value: Scalar[type]) -> Bool:
        @parameter
        @always_inline("nodebug")
        fn _check[width: Int](offset: Int) -> Bool:
            return any(self.unsafe_get[width](offset) == value)
        return vectorize_stoping[_check, simdwidthof[type]()](self._size)

    @always_inline("nodebug")
    fn cast[target_type: DType](self) -> Vector[target_type, bnd, fmt, spc]:
        var result = Vector[target_type, bnd, fmt, spc](size = len(self))
        @parameter
        @always_inline("nodebug")
        fn _cast[width: Int](offset: Int):
            result.unsafe_set[width](offset, self.unsafe_get[width](offset).cast[target_type]())
        vectorize[_cast, min(simdwidthof[type](), simdwidthof[target_type]())](len(self))
        return result

    @always_inline("nodebug")
    fn bitcast[target_type: DType](owned self) -> Vector[target_type, bnd, fmt, spc]:
        var result = Vector[target_type, bnd, fmt, spc]()
        result._data = self._data.bitcast[Scalar[target_type]]()
        result._size = (len(self) * bitwidthof[type]()) // bitwidthof[target_type]()
        __mlir_op.`lit.ownership.mark_destroyed`(Reference(self).value)
        return result

    @always_inline("nodebug")
    fn __any__(self) -> Bool:
        @parameter
        @always_inline("nodebug")
        fn _check[width: Int](offset: Int) -> Bool:
            return any(self.unsafe_get[width](offset) != 0)
        return vectorize_stoping[_check, simdwidthof[type]()](self._size)

    @always_inline("nodebug")
    fn __all__(self) -> Bool:
        @parameter
        @always_inline("nodebug")
        fn _check[width: Int](offset: Int) -> Bool:
            return any(self.unsafe_get[width](offset) == 0)
        return not vectorize_stoping[_check, simdwidthof[type]()](self._size)

    @always_inline("nodebug")
    fn _binary_op[type_out: DType, func: fn(a: SIMD[type, _], b: SIMD[type, a.size])->SIMD[type_out, a.size]](self, rhs: Vector[type, _, _, _]) -> Vector[type_out, bnd, fmt, spc]:
        debug_assert(len(self) == len(rhs), "size must be equal")
        var result: Vector[type_out, bnd, fmt, spc]
        result.__init__[False](size = len(self))
        @parameter
        @always_inline("nodebug")
        fn _run[width: Int](offset: Int):
            result.unsafe_set[width](offset, func(self.unsafe_get[width](offset), rhs.unsafe_get[width](offset)))
        vectorize[_run, simdwidthof[type]()](len(self))
        return result

    @always_inline("nodebug")
    fn _binary_op[type_out: DType, func: fn(a: SIMD[type, _], b: SIMD[type, a.size])->SIMD[type_out, a.size]](self, rhs: Scalar[type]) -> Vector[type_out, bnd, fmt, spc]:
        debug_assert(len(self) == len(rhs), "size must be equal")
        var result: Vector[type_out, bnd, fmt, spc]
        result.__init__[False](size = len(self))
        @parameter
        @always_inline("nodebug")
        fn _run[width: Int](offset: Int):
            result.unsafe_set[width](offset, func(self.unsafe_get[width](offset), rhs))
        vectorize[_run, simdwidthof[type]()](len(self))
        return result

    @always_inline("nodebug")
    fn _binary_iop[func: fn(a: SIMD[type, _], b: SIMD[type, a.size])->SIMD[a.type, a.size]](inout self, rhs: Vector[type, _, _, _]):
        debug_assert(len(self) == len(rhs), "size must be equal")
        @parameter
        @always_inline("nodebug")
        fn _run[width: Int](offset: Int):
            self.unsafe_set[width](offset, func(self.unsafe_get[width](offset), rhs.unsafe_get[width](offset)))
        vectorize[_run, simdwidthof[type]()](len(self))

    @always_inline("nodebug")
    fn _binary_iop[func: fn(a: SIMD[type, _], b: SIMD[type, a.size])->SIMD[a.type, a.size]](inout self, rhs: Scalar[type]):
        debug_assert(len(self) == len(rhs), "size must be equal")
        @parameter
        @always_inline("nodebug")
        fn _run[width: Int](offset: Int):
            self.unsafe_set[width](offset, func(self.unsafe_get[width](offset), rhs))
        vectorize[_run, simdwidthof[type]()](len(self))

    @always_inline("nodebug")
    fn all_eq(self, rhs: Vector[type, _, _, _]) -> Bool:
        if len(self) != len(rhs):
            return False
        @parameter
        @always_inline("nodebug")
        fn _check[width: Int](offset: Int) -> Bool:
            return any(self.unsafe_get[width](offset) != rhs.unsafe_get[width](offset))
        return not vectorize_stoping[_check, simdwidthof[type]()](len(self))

    @always_inline("nodebug")
    fn any_ne(self, rhs: Vector[type, _, _, _]) -> Bool:
        return not self.all_eq(rhs)

    @always_inline("nodebug")
    fn _eq(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool]:
        return self._binary_op[DType.bool, SIMD[type, _].__eq__](rhs)

    @always_inline("nodebug")
    fn _ne(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__ne__](rhs)

    @always_inline("nodebug")
    fn __eq__[__:None=None](self, rhs: Self) -> Bool:
        return self.all_eq(rhs)

    @always_inline("nodebug")
    fn __eq__(self, rhs: Self) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._eq(rhs)

    @always_inline("nodebug")
    fn __eq__(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._eq(rhs)

    @always_inline("nodebug")
    fn __eq__(self, rhs: Scalar[type]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__eq__](rhs)

    @always_inline("nodebug")
    fn __ne__[__:None=None](self, rhs: Self) -> Bool:
        return self.any_ne(rhs)

    @always_inline("nodebug")
    fn __ne__(self, rhs: Self) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._ne(rhs)

    @always_inline("nodebug")
    fn __ne__(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._ne(rhs)

    @always_inline("nodebug")
    fn __ne__(self, rhs: Scalar[type]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__ne__](rhs)

    @always_inline("nodebug")
    fn __lt__(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__lt__](rhs)

    @always_inline("nodebug")
    fn __lt__(self, rhs: Scalar[type]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__lt__](rhs)

    @always_inline("nodebug")
    fn __le__(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__le__](rhs)

    @always_inline("nodebug")
    fn __le__(self, rhs: Scalar[type]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__le__](rhs)

    @always_inline("nodebug")
    fn __gt__(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__gt__](rhs)

    @always_inline("nodebug")
    fn __gt__(self, rhs: Scalar[type]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__gt__](rhs)

    @always_inline("nodebug")
    fn __ge__(self, rhs: Vector[type, _, _, _]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__ge__](rhs)

    @always_inline("nodebug")
    fn __ge__(self, rhs: Scalar[type]) -> Vector[DType.bool, bnd, fmt, spc]:
        return self._binary_op[DType.bool, SIMD[type, _].__ge__](rhs)

    # +------( Arithmetic )------+ #
    #
    @always_inline("nodebug")
    fn __add__(self, rhs: Vector[type, _, _, _]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__add__](rhs)

    @always_inline("nodebug")
    fn __add__(self, rhs: Scalar[type]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__add__](rhs)

    @always_inline("nodebug")
    fn __sub__(self, rhs: Vector[type, _, _, _]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__sub__](rhs)

    @always_inline("nodebug")
    fn __sub__(self, rhs: Scalar[type]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__sub__](rhs)

    @always_inline("nodebug")
    fn __and__(self, rhs: Vector[type, _, _, _]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__and__](rhs)

    @always_inline("nodebug")
    fn __and__(self, rhs: Scalar[type]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__and__](rhs)

    @always_inline("nodebug")
    fn __or__(self, rhs: Vector[type, _, _, _]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__or__](rhs)

    @always_inline("nodebug")
    fn __or__(self, rhs: Scalar[type]) -> __type_of(self):
        return self._binary_op[type, SIMD[type, _].__or__](rhs)

    @always_inline("nodebug")
    fn __iadd__(inout self, rhs: Vector[type, _, _, _]):
        self._binary_iop[SIMD[type, _].__add__](rhs)

    @always_inline("nodebug")
    fn __iadd__(inout self, rhs: Scalar[type]):
        self._binary_iop[SIMD[type, _].__add__](rhs)

    @always_inline("nodebug")
    fn __isub__(inout self, rhs: Vector[type, _, _, _]):
        self._binary_iop[SIMD[type, _].__sub__](rhs)

    @always_inline("nodebug")
    fn __isub__(inout self, rhs: Scalar[type]):
        self._binary_iop[SIMD[type, _].__sub__](rhs)

    @always_inline("nodebug")
    fn __iand__(inout self, rhs: Vector[type, _, _, _]):
        self._binary_iop[SIMD[type, _].__and__](rhs)

    @always_inline("nodebug")
    fn __ior__(inout self, rhs: Scalar[type]):
        self._binary_iop[SIMD[type, _].__or__](rhs)


# +----------------------------------------------------------------------------------------------+ #
# | Vector Iter
# +----------------------------------------------------------------------------------------------+ #
# TODO: this could be merged with ArraySpan/ArrayIter?
#
@value
struct VectorIter[mutability: Bool, //, type: DType, bnd: SpanBound, fmt: ArrayFormat, lifetime: AnyLifetime[mutability].type, spc: AddressSpace](Formattable, Sized, Value):
    """Span for Array.

    Parameters:
        mutability: Whether the reference to the array is mutable.
        type: The DType of the vector.
        bnd: The boundary condition to use with subscripts.
        fmt: The default format used when printing the array.
        lifetime: The lifetime of the array.
        spc: The address space.
    """

    # +------[ alias ]------+ #
    #
    alias Pointer = UnsafePointer[Scalar[type], spc]

    # +------< Data >------+ #
    #
    var _src: Self.Pointer
    var start: Int
    var size: Int
    var step: Int

    # +------( Lifecycle )------+ #
    #
    @always_inline("nodebug")
    fn __init__(inout self):
        self._src = Self.Pointer()
        self.start = 0
        self.size = 0
        self.step = 1

    @always_inline("nodebug")
    fn __init__(inout self, src: Self.Pointer, owned size: Int):
        self._src = src
        self.start = 0
        self.size = size
        self.step = 1

    @always_inline("nodebug")
    fn __init__(inout self, src: Self.Pointer, owned slice: Slice):
        self._src = src
        self.start = slice.start.value()
        self.size = max(ceildiv(slice.end.value() - self.start, slice.step), 0)
        self.step = slice.step

    @always_inline("nodebug")
    fn __init__(inout self, ref[lifetime, spc._value.value] src: Vector[type, bnd, fmt, spc]):
        self = VectorIter[type, bnd, fmt, lifetime, spc](src._data, src._size)

    # +------( Subscript )------+ #
    #
    @always_inline("nodebug")
    fn __getitem__(self, owned idx: Int) -> Scalar[type]:
        bnd.adjust(idx, self.size)
        return (self._src + self.start + idx * self.step)[]

    @always_inline("nodebug")
    fn __setitem__(self, owned idx: Int, value: Scalar[type]):
        bnd.adjust(idx, self.size)
        (self._src + self.start + idx * self.step)[] = value

    @always_inline("nodebug")
    fn __getitem__(self, owned slice: Slice) -> Self:
        bnd.adjust(slice, self.size)
        var start = slice.start.value() * self.step + self.start
        var step = slice.step * self.step
        var size = ceildiv(slice.end.value() - slice.start.value(), slice.step)
        return Self(self._src, start, size, step)

    @always_inline("nodebug")
    fn __setitem__[lifetime: MutableLifetime](self: VectorIter[type, bnd, fmt, lifetime, spc], owned slice: Slice, value: VectorIter[type, _, _, _, _]):
        var sliced_self = self[slice]
        for idx in range(min(len(sliced_self), len(value))):
            self[idx] = value[idx]

    # +------( Iterate )------+ #
    #
    @always_inline("nodebug")
    fn __iter__(self) -> Self:
        return self

    @always_inline("nodebug")
    fn __reversed__(self) -> Self:
        return Self(self._src, self.start + (self.size - 1) * self.step, self.size, -self.step)

    @always_inline("nodebug")
    fn __next__(inout self) -> Reference[Scalar[type], lifetime, spc]:
        var result = Reference[Scalar[type], lifetime, spc](self._src[self.start])
        self.start += self.step
        self.size -= 1
        return result[]

    # +------( Format )------+ #
    #
    @always_inline("nodebug")
    fn __str__[fmt: ArrayFormat = fmt](self) -> String:
        var result: String = ""
        var writer = result._unsafe_to_formatter()
        self.format_to[fmt](writer)
        return result

    @always_inline("nodebug")
    fn _get_item_align(self) -> Int:
        var longest = 0
        for item in self:
            longest = max(longest, len(str(Scalar[type](item[]))))
        return longest

    @always_inline("nodebug")
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter):
        @parameter
        if fmt.pad:
            self.format_to[fmt](writer, self._get_item_align())
            return

        var _self = self
        @parameter
        @always_inline("nodebug")
        fn _write():
            write_to(writer, fmt.item_color, str(Scalar[type](_self.__next__()[])))
        write_sep[_write, fmt](writer, len(self))

    @always_inline("nodebug")
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter, align: Int):
        var _self = self
        @parameter
        @always_inline("nodebug")
        fn _str():
            write_align[fmt.pad, fmt.item_color](writer, str(Scalar[type](_self.__next__()[])), align)
        write_sep[_str, fmt](writer, len(self))

    # +------( Operations )------+ #
    #
    @always_inline("nodebug")
    fn __bool__(self) -> Bool:
        return self.size != 0

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        return self.size

    @always_inline("nodebug")
    fn __eq__(self, rhs: Self) -> Bool:
        return self.__eq__[None](rhs)

    @always_inline("nodebug")
    fn __eq__[__:None=None](self, rhs: VectorIter[type, _, _, _, _]) -> Bool:
        if len(self) != len(rhs):
            return False
        for idx in range(len(self)):
            if self[idx] != rhs[idx]:
                return False
        return True

    @always_inline("nodebug")
    fn __ne__(self, rhs: Self) -> Bool:
        return self.__ne__[None](rhs)

    @always_inline("nodebug")
    fn __ne__[__:None=None](self, rhs: VectorIter[type, _, _, _, _]) -> Bool:
        if len(self) != len(rhs):
            return True
        for idx in range(len(self)):
            if self[idx] != rhs[idx]:
                return True
        return False

    @always_inline("nodebug")
    fn __contains__(self, element: Scalar[type]) -> Bool:
        for item in self:
            if item[] == element:
                return True
        return False

    @always_inline("nodebug")
    fn index(self, element: Scalar[type]) raises -> Int:
        for idx in range(len(self)):
            if self[idx] == element:
                return idx
        raise Error("NoValue")

    @always_inline("nodebug")
    fn count(self, value: Scalar[type]) -> Int:
        var result = 0
        for item in self:
            if item[] == value:
                result += 1
        return result

    @always_inline("nodebug")
    fn clear[lifetime: MutableLifetime, //](self: VectorIter[type, bnd, fmt, lifetime, spc]):
        self.fill(0)

    @always_inline("nodebug")
    fn fill[lifetime: MutableLifetime, //](self: VectorIter[type, bnd, fmt, lifetime, spc], value: Scalar[type]):
        for item in self:
            item[] = value