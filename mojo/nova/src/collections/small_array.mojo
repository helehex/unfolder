# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Small Array."""

from ..memory import _del, _take, _copy, _move


fn _small_array_construction_checks[size: Int]():
    constrained[size > 0, "number of elements in `StaticTuple` must be > 0"]()


# +----------------------------------------------------------------------------------------------+ #
# | Small Array
# +----------------------------------------------------------------------------------------------+ #
#
struct SmallArray[T: Value, size: Int, bnd: SpanBound = SpanBound.Lap, fmt: ArrayFormat = "[, ]"](
    Formattable, Sized, Value
):
    """A stack allocated array."""

    # +------[ Alias ]------+ #
    #
    alias Data = __mlir_type[`!pop.array<`, size.value, `, `, T, `>`]

    # +------< Data >------+ #
    #
    var _data: Self.Data

    # +------( Lifecycle )------+ #
    #
    @always_inline
    fn __init__[clear: Bool = True](inout self):
        @parameter
        if clear:
            self.__init__(T())
        else:
            _small_array_construction_checks[size]()
            self._data = __mlir_op.`kgen.undef`[_type = Self.Data]()

    @always_inline
    fn __init__(inout self, fill: T):
        self.__init__[False]()

        @parameter
        for idx in range(size):
            _copy(self.unsafe_ptr() + idx, fill)

    @always_inline
    fn __init__(inout self, owned *elems: T):
        self = Self(storage=elems^)

    @always_inline("nodebug")
    fn __init__(inout self, *, owned storage: VariadicListMem[T, _]):
        debug_assert(len(storage) == size, "Elements must be of length size")
        self.__init__[False]()

        @parameter
        for idx in range(size):
            _move(self.unsafe_ptr() + idx, UnsafePointer.address_of(storage[idx]))
        storage._is_owned = False

    fn __copyinit__(inout self, other: Self):
        self.__init__[False]()

        @parameter
        for idx in range(size):
            _copy(self.unsafe_ptr() + idx, other.unsafe_ptr() + idx)

    fn __moveinit__(inout self, owned other: Self):
        self.__init__[False]()

        @parameter
        for idx in range(size):
            _move(self.unsafe_ptr() + idx, other.unsafe_ptr() + idx)

    fn __del__(owned self):
        @parameter
        for idx in range(size):
            _del(self.unsafe_ptr() + idx)

    # +------( Iterate )------+ #
    #
    @always_inline("nodebug")
    fn __iter__(ref [_]self) -> ArrayIter[T, bnd, fmt, __lifetime_of(self)]:
        return self[:]

    # +------( Subscript )------+ #
    #
    @always_inline("nodebug")
    fn __getitem__(ref [_]self, owned idx: Int) -> ref [__lifetime_of(self)] T:
        bnd.adjust(idx, size)
        return self.unsafe_ref(idx)

    @always_inline("nodebug")
    fn __getitem__[
        bnd: SpanBound = bnd
    ](ref [_]self, owned slice: Slice) -> ArrayIter[T, bnd, fmt, __lifetime_of(self)]:
        bnd.adjust(slice, size)
        return ArrayIter[T, bnd, fmt, __lifetime_of(self)](self.unsafe_ptr(), slice)

    @always_inline("nodebug")
    fn unsafe_ref(ref [_]self, idx: Int) -> ref [__lifetime_of(self)] T:
        return UnsafePointer(
            __mlir_op.`pop.array.gep`(UnsafePointer.address_of(self._data).address, idx.value)
        )[]

    @always_inline
    fn unsafe_ptr(self) -> UnsafePointer[T]:
        """Get an `UnsafePointer` to the underlying array.

        That pointer is unsafe but can be used to read or write to the array.
        Be careful when using this. As opposed to a pointer to a `List`,
        this pointer becomes invalid when the `InlineArray` is moved.

        Make sure to refresh your pointer every time the `InlineArray` is moved.

        Returns:
            An `UnsafePointer` to the underlying array.
        """
        return UnsafePointer.address_of(self._data).bitcast[T]()

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
            longest = max(longest, len(str(item[])))
        return longest

    @always_inline("nodebug")
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter):
        @parameter
        if fmt.pad:
            self.format_to[fmt](writer, self._get_item_align())
            return

        var iter = self.__iter__()

        @parameter
        @always_inline("nodebug")
        fn _write():
            writer.write(fmt.item_color, str(iter.__next__()[]))

        write_sep[_write, fmt](writer, len(iter))

    @always_inline("nodebug")
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter, align: Int):
        var iter = self.__iter__()

        @parameter
        @always_inline("nodebug")
        fn _str():
            write_align[fmt.pad, fmt.item_color](writer, str(iter.__next__()[]), align)

        write_sep[_str, fmt](writer, len(iter))

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        return size

    @always_inline("nodebug")
    fn __bool__(self) -> Bool:
        return True

    @always_inline("nodebug")
    fn __eq__[
        size: Int = size, bnd: SpanBound = bnd, fmt: ArrayFormat = fmt
    ](self, rhs: SmallArray[T, size, bnd, fmt]) -> Bool:
        return self[:] == rhs[:]

    @always_inline("nodebug")
    fn __ne__[
        size: Int = size, bnd: SpanBound = bnd, fmt: ArrayFormat = fmt
    ](self, rhs: SmallArray[T, size, bnd, fmt]) -> Bool:
        return self[:] != rhs[:]
