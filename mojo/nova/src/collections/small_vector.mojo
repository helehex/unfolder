# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Small Vector."""

from ..memory import _del, _take, _copy, _move


fn _small_array_construction_checks[size: Int]():
    constrained[size >= 0, "number of elements in `SmallArray` must be >= 0"]()


# +----------------------------------------------------------------------------------------------+ #
# | Small Array
# +----------------------------------------------------------------------------------------------+ #
#
struct SmallVector[
    type: DType, size: Int, bnd: SpanBound = SpanBound.Lap, fmt: ArrayFormat = "[, ]"
](Formattable, Sized, Value):
    """A stack allocated array."""

    # +------[ Alias ]------+ #
    #
    alias Data = __mlir_type[`!pop.array<`, size.value, `, `, Scalar[type], `>`]

    # +------< Data >------+ #
    #
    var _data: Self.Data

    # +------( Lifecycle )------+ #
    #
    @always_inline
    fn __init__[clear: Bool = True](inout self):
        _small_array_construction_checks[size]()

        @parameter
        if clear:
            self.__init__(Scalar[type]())
        else:
            self._data = __mlir_op.`kgen.undef`[_type = Self.Data]()

    @always_inline
    fn __init__(inout self, fill: Scalar[type]):
        self.__init__[False]()

        @parameter
        for idx in range(size):
            self.unsafe_set(idx, fill)

    @always_inline
    fn __init__(inout self, owned *elems: Scalar[type]):
        self = Self(storage=elems^)

    @always_inline
    fn __init__[
        width: Int = 1
    ](inout self, *, owned storage: VariadicListMem[SIMD[type, width], _]):
        """Creates a new vector with the given values."""
        self.__init__[False]()

        @parameter
        @always_inline
        fn _set[_width: Int](idx: Int):
            @parameter
            if width != 1 and _width == 1:
                self.unsafe_set[1](idx, storage[(idx // width) % len(storage)][idx % width])
            else:
                self.unsafe_set[width](idx, storage[(idx // width) % len(storage)])

        vectorize[_set, width](size)

    @always_inline
    fn __init__[width: Int = 1](inout self, *values: SIMD[type, width]):
        """Creates a new vector with the given values."""
        self.__init__[False]()
        for idx in range(len(values)):
            self.unsafe_set[width](idx * width, values[idx])

    fn __copyinit__(inout self, other: Self):
        self._data = other._data

    fn __moveinit__(inout self, owned other: Self):
        self._data = other._data

    # +------( Cast )------+ #
    #
    @always_inline
    fn cast[target_type: DType](owned self) -> SmallVector[target_type, size, bnd, fmt]:
        var result: SmallVector[target_type, size, bnd, fmt]
        result.__init__[False]()

        @parameter
        @always_inline
        fn _cast[width: Int](offset: Int):
            result.unsafe_set[width](offset, self.unsafe_get[width](offset).cast[target_type]())

        vectorize[_cast, min(simdwidthof[type](), simdwidthof[target_type]())](len(self))
        return result

    # +------( Format )------+ #
    #
    @always_inline
    fn __str__[fmt: ArrayFormat = fmt](self) -> String:
        var result: String = ""
        var writer = result._unsafe_to_formatter()
        self.format_to[fmt](writer)
        return result

    @always_inline
    fn _get_item_align(self) -> Int:
        var longest = 0
        for item in self:
            longest = max(longest, len(str(item[])))
        return longest

    @always_inline
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter):
        @parameter
        if fmt.pad:
            self.format_to[fmt](writer, self._get_item_align())
            return

        var iter = self.__iter__()

        @parameter
        @always_inline
        fn _write():
            writer.write(fmt.item_color, str(iter.__next__()[]))

        write_sep[_write, fmt](writer, len(iter))

    @always_inline
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter, align: Int):
        var iter = self.__iter__()

        @parameter
        @always_inline
        fn _str():
            write_align[fmt.pad, fmt.item_color](writer, str(iter.__next__()[]), align)

        write_sep[_str, fmt](writer, len(iter))

    # +------( Iterate )------+ #
    #
    @always_inline
    fn __iter__(ref [_]self) -> VectorIter[type, bnd, fmt, __lifetime_of(self)]:
        return self[:]

    # +------( Subscript )------+ #
    #
    @always_inline
    fn __getitem__[
        width: Int = 1, bnd: SpanBound = bnd
    ](ref [_]self, owned idx: Int) -> SIMD[type, width]:
        @parameter
        if width != 1 and bnd != SpanBound.Unsafe:
            if idx + width > size:
                var result = SIMD[type, width]()

                @parameter
                for lane in range(width):
                    var idx2 = idx + lane
                    bnd.adjust(idx2, size)
                    result[lane] = self.unsafe_get[1](idx2)
                return result
        bnd.adjust(idx, size)
        return self.unsafe_get[width](idx)

    @always_inline
    fn unsafe_get[width: Int = 1](ref [_]self, idx: Int) -> SIMD[type, width]:
        return simd_load[width](self.unsafe_ptr(), idx)

    @always_inline
    fn __setitem__[
        width: Int = 1, bnd: SpanBound = bnd
    ](inout self, owned idx: Int, value: SIMD[type, width]):
        @parameter
        if width != 1 and bnd != SpanBound.Unsafe:
            if idx + width > size:

                @parameter
                for lane in range(width):
                    var idx2 = idx + lane
                    bnd.adjust(idx2, size)
                    self.unsafe_set[1](idx2, value[lane])
                return
        bnd.adjust(idx, size)
        self.unsafe_set[width](idx, value)

    @always_inline
    fn unsafe_set[width: Int = 1](inout self, idx: Int, value: SIMD[type, width]):
        simd_store[width](self.unsafe_ptr(), idx, value)

    @always_inline
    fn __getitem__[
        bnd: SpanBound = bnd
    ](ref [_]self, owned slice: Slice) -> VectorIter[type, bnd, fmt, __lifetime_of(self)]:
        bnd.adjust(slice, size)
        return VectorIter[type, bnd, fmt, __lifetime_of(self)](self.unsafe_ptr(), slice)

    @always_inline
    fn __setitem__[
        lif: AnyLifetime[True].type, //
    ](ref [lif]self, owned slice: Slice, value: VectorIter[type, _, _, _, _]):
        var sliced_self = self[slice]
        for idx in range(min(len(sliced_self), len(value))):
            self[idx] = value.unsafe_ref(idx)

    @always_inline
    fn unsafe_ptr(self) -> UnsafePointer[Scalar[type]]:
        """Get an `UnsafePointer` to the underlying array.

        That pointer is unsafe but can be used to read or write to the array.
        Be careful when using this. As opposed to a pointer to a `List`,
        this pointer becomes invalid when the `InlineArray` is moved.

        Make sure to refresh your pointer every time the `InlineArray` is moved.

        Returns:
            An `UnsafePointer` to the underlying array.
        """
        return UnsafePointer.address_of(self._data).bitcast[Scalar[type]]()

    @always_inline
    fn clear(self):
        memclr(self.unsafe_ptr(), size)

    @always_inline
    fn fill(self, value: Scalar[type]):
        memset(self.unsafe_ptr(), value, size)

    # +------( Operations )------+ #
    #
    @always_inline
    fn __len__(self) -> Int:
        return size

    @always_inline
    fn __bool__(self) -> Bool:
        return True

    @always_inline
    fn __is__(self, rhs: Self) -> Bool:
        return UnsafePointer.address_of(self) == UnsafePointer.address_of(rhs)

    @always_inline
    fn __isnot__(self, rhs: Self) -> Bool:
        return UnsafePointer.address_of(self) != UnsafePointer.address_of(rhs)

    @always_inline
    fn __eq__[
        size: Int = size, bnd: SpanBound = bnd, fmt: ArrayFormat = fmt
    ](self, rhs: SmallVector[type, size, bnd, fmt]) -> Bool:
        return self[:] == rhs[:]

    @always_inline
    fn __ne__[
        size: Int = size, bnd: SpanBound = bnd, fmt: ArrayFormat = fmt
    ](self, rhs: SmallVector[type, size, bnd, fmt]) -> Bool:
        return self[:] != rhs[:]

    @always_inline
    fn __any__(self) -> Bool:
        @parameter
        @always_inline
        fn _check[width: Int](offset: Int) -> Bool:
            return any(self.unsafe_get[width](offset) != 0)

        return vectorize_stoping[_check, simdwidthof[type]()](size)

    @always_inline
    fn __all__(self) -> Bool:
        @parameter
        @always_inline
        fn _check[width: Int](offset: Int) -> Bool:
            return any(self.unsafe_get[width](offset) == 0)

        return not vectorize_stoping[_check, simdwidthof[type]()](size)
