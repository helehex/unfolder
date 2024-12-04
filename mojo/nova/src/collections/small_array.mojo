# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Small Array."""

from ..memory import _del, _take, _copy, _move


fn _small_array_construction_checks[size: Int]():
    constrained[size >= 0, "number of elements in `SmallArray` must be >= 0"]()


# +----------------------------------------------------------------------------------------------+ #
# | Small Array
# +----------------------------------------------------------------------------------------------+ #
#
struct SmallArray[T: Value, size: Int, bnd: SpanBound = SpanBound.Lap, fmt: ArrayFormat = "[, ]"](
    Writable, Sized, Value
):
    """A stack allocated collection of homogeneous scalars, with static size, and appending semantics.
    """

    # +------[ Alias ]------+ #
    #
    alias Data = __mlir_type[`!pop.array<`, size.value, `, `, T, `>`]

    # +------< Data >------+ #
    #
    var _data: Self.Data

    # +------( Lifecycle )------+ #
    #
    @always_inline
    fn __init__[clear: Bool = True](mut self):
        _small_array_construction_checks[size]()

        @parameter
        if clear:
            self.__init__(T())
        else:
            self._data = __mlir_op.`kgen.param.constant`[
                _type = Self.Data, value = __mlir_attr[`#kgen.unknown : `, Self.Data]
            ]()

    @always_inline
    fn __init__(out self, fill: T):
        self.__init__[False]()

        @parameter
        for idx in range(size):
            _copy(self.unsafe_ptr() + idx, fill)

    @always_inline
    fn __init__(out self, owned *elems: T):
        self = Self(storage=elems^)

    @always_inline
    fn __init__(out self, *, owned storage: VariadicListMem[T, _]):
        debug_assert(len(storage) == size, "Elements must be of length size")
        self.__init__[False]()

        @parameter
        for idx in range(size):
            _move(self.unsafe_ptr() + idx, UnsafePointer.address_of(storage[idx]))
        storage._is_owned = False

    fn __copyinit__(out self, other: Self):
        self.__init__[False]()

        @parameter
        for idx in range(size):
            _copy(self.unsafe_ptr() + idx, other.unsafe_ptr() + idx)

    fn __moveinit__(out self, owned other: Self):
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
    @always_inline
    fn __iter__(ref [_]self) -> ArrayIter[T, bnd, fmt, __origin_of(self)]:
        return self[:]

    # +------( Subscript )------+ #
    #
    @always_inline
    fn __getitem__(ref [_]self, owned idx: Int) -> ref [__origin_of(self)] T:
        bnd.adjust(idx, size)
        return self.unsafe_ref(idx)

    @always_inline
    fn __getitem__[
        bnd: SpanBound = bnd
    ](ref [_]self, owned slice: Slice) -> ArrayIter[T, bnd, fmt, __origin_of(self)]:
        bnd.adjust(slice, size)
        return ArrayIter[T, bnd, fmt, __origin_of(self)](self.unsafe_ptr(), slice)

    @always_inline
    fn unsafe_ref(ref [_]self, idx: Int) -> ref [__origin_of(self)] T:
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
    @always_inline
    fn __str__[fmt: ArrayFormat = fmt](self) -> String:
        var result: String = ""
        self.write_to[fmt=fmt](result)
        return result

    @always_inline
    fn _get_item_align(self) -> Int:
        var longest = 0
        for item in self:
            longest = max(longest, len(str(item[])))
        return longest

    @always_inline
    fn write_to[WriterType: Writer, //, fmt: ArrayFormat = fmt](self, mut writer: WriterType):
        @parameter
        if fmt.pad:
            self.write_to[fmt=fmt](writer, self._get_item_align())
            return

        var iter = self.__iter__()

        @parameter
        @always_inline
        fn _write():
            writer.write(fmt.item_color, str(iter.__next__()[]))

        write_sep[_write, fmt](writer, len(iter))

    @always_inline
    fn write_to[
        WriterType: Writer, //, fmt: ArrayFormat = fmt
    ](self, mut writer: WriterType, align: Int):
        var iter = self.__iter__()

        @parameter
        @always_inline
        fn _str():
            write_align[fmt.pad, fmt.item_color](writer, str(iter.__next__()[]), align)

        write_sep[_str, fmt](writer, len(iter))

    @always_inline
    fn __len__(self) -> Int:
        return size

    @always_inline
    fn __bool__(self) -> Bool:
        return True

    @always_inline
    fn __eq__[
        size: Int = size, bnd: SpanBound = bnd, fmt: ArrayFormat = fmt
    ](self, rhs: SmallArray[T, size, bnd, fmt]) -> Bool:
        return self[:] == rhs[:]

    @always_inline
    fn __ne__[
        size: Int = size, bnd: SpanBound = bnd, fmt: ArrayFormat = fmt
    ](self, rhs: SmallArray[T, size, bnd, fmt]) -> Bool:
        return self[:] != rhs[:]
