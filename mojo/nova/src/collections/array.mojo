# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Array."""

from ..memory import _init, _copy, _move, _take, _del
from math import ceildiv


# +----------------------------------------------------------------------------------------------+ #
# | Array
# +----------------------------------------------------------------------------------------------+ #
#
struct Array[T: Value, bnd: SpanBound = SpanBound.Lap, fmt: ArrayFormat = "[, ]"](
    Formattable, Sized, Boolable, Value
):
    """A heap allocated array.

    Parameters:
        T: The type of elements in the array.
        bnd: The boundary condition to use with subscripts.
        fmt: The default format used when printing the array.
    """

    # +------< Data >------+ #
    #
    var _data: UnsafePointer[T]
    var _size: Int

    # +------( Lifecycle )------+ #
    #
    @always_inline
    fn __init__(inout self):
        """Creates a null array with zero size."""
        self._data = UnsafePointer[T]()
        self._size = 0

    @always_inline
    fn __init__[clear: Bool = True](inout self, *, size: Int):
        """Creates a new array and fills it with default values."""
        self._data = UnsafePointer[T].alloc(size)
        self._size = size

        @parameter
        if clear:
            _init(self._data, size)

    @always_inline
    fn __init__(inout self, *items: T):
        """Creates a new array with the given items."""
        self.__init__(items)

    @always_inline
    fn __init__(inout self, items: VariadicListMem[T, _]):
        """Creates a new array with the given items."""
        self.__init__[False](size=len(items))
        for idx in range(self._size):
            _copy(self._data + idx, items[idx])

    @always_inline
    fn __init__(inout self, *items: T, size: Int):
        """Creates a new array with the given items."""
        self.__init__[False](size=size)
        for idx in range(size):
            _copy(self._data + idx, items[idx % len(items)])

    @always_inline
    fn __init__[__: None = None](inout self, *arrays: Array[T, _, _]):
        """Creates a new array by joining existing arrays."""
        var size = 0
        for array in arrays:
            size += len(array[])
        self.__init__[False](size=size)
        var dst = self._data
        for array in arrays:
            _copy(dst, array[]._data, len(array[]))
            dst += len(array[])

    @always_inline
    fn __init__[__: None = None](inout self, *arrays: Array[T, _, _], size: Int):
        """Creates a new array by joining existing arrays."""
        self.__init__[False](size=size)
        var idx = 0
        var empty = False
        while not empty:
            for array in arrays:
                if idx + len(array[]) < size:
                    _copy(self._data + idx, array[]._data, len(array[]))
                    idx += len(array[])
                else:
                    _copy(self._data + idx, array[]._data, size - idx)
                    return
            empty = idx == 0
        self._data.free()
        __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(self))
        self = Self(size=size)

    # @always_inline
    # fn __init__(inout self, owned tuple: Tuple):
    #     """Creates a new array with the given tuple of elements."""
    #     _constrain_homo[T, tuple.element_types]()
    #     self._size = len(tuple)
    #     self._data = UnsafePointer[T].alloc(self._size)

    #     @parameter
    #     fn _set[idx: Int]():
    #         movedata(self._data + idx, UnsafePointer(tuple[idx]).bitcast[T]())

    #     unroll[_set, _len[tuple.element_types]()]()
    #     __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(tuple))

    @always_inline
    fn __init__[__: None = None](inout self, other: ArrayIter[T, _, _, _]):
        """Copy the data from an array iterator into this one."""
        self.__init__[False](size=len(other))
        _copy(self._data, other)

    # # for converting an array to a different bound/format.
    # # conflicts with other initializers. maybe use copyinit/moveinit instead?
    # @always_inline
    # fn __init__[__: None = None](inout self, owned other: Array[T, _, _]):
    #     """Creates a null array with zero size."""
    #     self._data = other._data
    #     self._size = other._size
    #     __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(other))

    @always_inline
    fn __copyinit__(inout self, other: Self):
        """Copy an existing array into the new array."""
        if other._data:
            self.__init__[False](size=len(other))
            _copy(self._data, other._data, len(other))
        else:
            self = Self()

    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        """Move an existing array into the new array."""
        self._data = other._data
        self._size = other._size

    @always_inline
    fn __del__(owned self):
        """Delete the items in this array."""
        if self._data:
            _del(self._data, self._size)
            self._data.free()

    # +------( Subscript )------+ #
    #
    @always_inline
    fn __getitem__[
        bnd: SpanBound = bnd
    ](ref [_]self, owned idx: Int) -> ref [__lifetime_of(self)] T:
        bnd.adjust(idx, self._size)
        return self.unsafe_get(idx)

    @always_inline
    fn unsafe_get(ref [_]self, owned idx: Int) -> ref [__lifetime_of(self)] T:
        return (self._data + idx)[]

    @always_inline
    fn __getitem__[
        bnd: SpanBound = bnd
    ](ref [_]self, owned slice: Slice) -> ArrayIter[T, bnd, fmt, __lifetime_of(self)]:
        bnd.adjust(slice, self._size)
        return ArrayIter[T, bnd, fmt, __lifetime_of(self)](self._data, slice)

    # @always_inline
    # fn __setitem__(inout self, owned slice: Slice, value: ArrayIter[T, _, _, _]):
    #     var sliced_self = self[slice]
    #     for idx in range(min(len(sliced_self), len(value))):
    #         self[idx] = value[idx]

    @always_inline
    fn rebound[bound: SpanBound](owned self) -> Array[T, bound, fmt]:
        var result: Array[T, bound, fmt]
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(result))
        result._data = self._data
        result._size = self._size
        __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(self))
        return result^

    # +------( Iterate )------+ #
    #
    @always_inline
    fn __iter__(ref [_]self) -> ArrayIter[T, bnd, fmt, __lifetime_of(self)]:
        return self[:]

    @always_inline
    fn __reversed__(ref [_]self) -> ArrayIter[T, bnd, fmt, __lifetime_of(self)]:
        return self[::-1]

    # +------( Format )------+ #
    #
    @always_inline
    fn __str__[fmt: ArrayFormat = fmt](self) -> String:
        return self[:].__str__[fmt]()

    @always_inline
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter):
        return self[:].format_to[fmt](writer)

    @always_inline
    fn format_to[fmt: ArrayFormat = fmt](self, inout writer: Formatter, align: Int):
        return self[:].format_to[fmt](writer, align)

    @staticmethod
    @always_inline
    fn eval[fmt: ArrayFormat = fmt](owned txt: String) raises -> Self:
        """Evaluate the string as an array."""

        @parameter
        if _type_is_eq[T, Int]():
            var split_txt = txt.removeprefix(fmt.beg).removesuffix(fmt.end or " ").split(fmt.sep)

            if len(split_txt) == 0:
                return Self()

            var result: Self
            result.__init__[False](size=len(split_txt))
            var ptr = rebind[UnsafePointer[Int]](result._data)

            for idx in range(len(split_txt)):
                _move(ptr + idx, int(split_txt[idx]))

            return result
        raise "No Conversion"

    # +------( Operations )------+ #
    #
    @always_inline
    fn __len__(self) -> Int:
        """Returns the size of this array."""
        return self._size

    @always_inline
    fn __bool__(self) -> Bool:
        """Returns true if this array has a size greater than zero."""
        return self._size != 0

    @always_inline
    fn __is__(self, other: Self) -> Bool:
        return self._data == other._data

    @always_inline
    fn __isnot__(self, other: Self) -> Bool:
        return self._data != other._data

    @always_inline
    fn __eq__[bnd: SpanBound = bnd, fmt: ArrayFormat = fmt](self, rhs: Array[T, bnd, fmt]) -> Bool:
        return self[:] == rhs[:]

    @always_inline
    fn __ne__[bnd: SpanBound = bnd, fmt: ArrayFormat = fmt](self, rhs: Array[T, bnd, fmt]) -> Bool:
        return self[:] != rhs[:]

    @always_inline
    fn __contains__(self, value: T) -> Bool:
        return value in self[:]

    @always_inline
    fn __add__(self, rhs: ArrayIter[T, _, _, _]) -> Self:
        return self._append(rhs)

    @always_inline
    fn __add__(self, rhs: T) -> Self:
        return self._append(rhs)

    @always_inline
    fn __mul__(self, rhs: Int) -> Self:
        return Self(self, size=len(self) * rhs)

    @always_inline
    fn __iadd__(inout self, rhs: ArrayIter[T, _, _, _]):
        self.append(rhs)

    @always_inline
    fn __iadd__(inout self, rhs: T):
        self.append(rhs)

    @always_inline
    fn __imul__(inout self, rhs: Int):
        self = self * rhs

    # +------( Append )------+ #
    #
    @always_inline
    fn _append(self, item: T) -> Self:
        var new_array: Self
        new_array.__init__[False](size=len(self) + 1)
        _move(new_array._data, self._data, len(self))
        _copy(new_array._data + len(self), item)
        return new_array

    @always_inline
    fn _append(self, owned items: ArrayIter[T, _, _, _]) -> Self:
        var new_array: Self
        new_array.__init__[False](size=len(self) + len(items))
        _move(new_array._data, self._data, len(self))
        _copy(new_array._data + len(self), items)
        return new_array

    @always_inline
    fn append(inout self, item: T):
        var new_array: Self
        new_array.__init__[False](size=len(self) + 1)
        _move(new_array._data, self._data, len(self))
        _copy(new_array._data + len(self), item)
        self._data.free()
        __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(self))
        self = new_array

    @always_inline
    fn append(inout self, items: ArrayIter[T, _, _, _]):
        var new_array: Self
        new_array.__init__[False](size=len(self) + len(items))
        _move(new_array._data, self._data, len(self))
        _copy(new_array._data + len(self), items)
        self._data.free()
        __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(self))
        self = new_array

    # +------( Insert )------+ #
    #
    @always_inline
    fn inserted[bnd: SpanBound = bnd](self, owned idx: Int, item: T) -> Self:
        bnd.adjust(idx, len(self))
        var new_array: Self
        new_array.__init__[False](size=len(self) + 1)
        _copy(new_array._data, self._data, idx)
        _copy(new_array._data + idx, item)
        _copy(new_array._data + idx + 1, self._data + idx, self._size - idx)
        return new_array

    @always_inline
    fn inserted[bnd: SpanBound = bnd](self, owned idx: Int, items: ArrayIter[T, _, _, _]) -> Self:
        bnd.adjust(idx, len(self))
        var new_array: Self
        new_array.__init__[False](size=len(self) + len(items))
        _copy(new_array._data, self._data, idx)
        _copy(new_array._data + idx, items)
        _copy(new_array._data + idx + len(items), self._data + idx, self._size - idx)
        return new_array

    @always_inline
    fn insert(inout self, owned idx: Int, item: T):
        bnd.adjust(idx, len(self))
        var new_array: Self
        new_array.__init__[False](size=len(self) + 1)
        _move(new_array._data, self._data, idx)
        _copy(new_array._data + idx, item)
        _move(new_array._data + idx + 1, self._data + idx, self._size - idx)
        self._data.free()
        __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(self))
        self = new_array

    @always_inline
    fn insert(inout self, owned idx: Int, items: ArrayIter[T, _, _, _]):
        bnd.adjust(idx, len(self))
        var new_array: Self
        new_array.__init__[False](size=len(self) + len(items))
        _move(new_array._data, self._data, idx)
        _copy(new_array._data + idx, items)
        _move(new_array._data + idx + len(items), self._data + idx, self._size - idx)
        self._data.free()
        __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(self))
        self = new_array

    # +------( Remove )------+ #
    #
    @always_inline
    fn remove(inout self, value: T):
        try:
            _ = self.pop(self.index(value))
        except:
            pass

    # +------( Index )------+ #
    #
    @always_inline
    fn index(self, value: T) raises -> Int:
        return self[:].index(value)

    # +------( Count )------+ #
    #
    @always_inline
    fn count(self, value: T) -> Int:
        return self[:].count(value)

    # +------( Resize )------+ #
    #
    @always_inline
    fn unsafe_shrinked(self, size: Int) -> Self:
        var new_array: Self
        new_array.__init__[False](size=size)
        _copy(new_array._data, self._data, size)
        return new_array

    @always_inline
    fn unsafe_shrink(inout self, size: Int):
        _del(self._data + size, self._size - size)
        self._size = size

    @always_inline
    fn unsafe_expanded(self, size: Int) -> Self:
        var new_array: Self
        new_array.__init__[False](size=size)
        _copy(new_array._data, self._data, self._size)
        _init(new_array._data + self._size, size - self._size)
        return new_array

    @always_inline
    fn unsafe_expand(inout self, size: Int):
        var new_array: Self
        new_array.__init__[False](size=size)
        _move(new_array._data, self._data, self._size)
        _init(new_array._data + self._size, size - self._size)
        self._data.free()
        __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(self))
        self = new_array

    @always_inline
    fn resized(self, size: Int) -> Self:
        return self.unsafe_expanded(size) if size > self._size else self.unsafe_shrinked(size)

    @always_inline
    fn resize(inout self, size: Int):
        self.unsafe_expand(size) if size > self._size else self.unsafe_shrink(size)

    # +------( Pop )------+ #
    #
    @always_inline
    fn unsafe_pop(inout self) -> T:
        self._size -= 1
        return _take(self._data + len(self))

    @always_inline
    fn unsafe_pop(inout self, idx: Int) -> T:
        self._size -= 1
        var result = _take(self._data + idx)
        _move(self._data + idx, self._data + idx + 1, self._size - idx)
        return result

    @always_inline
    fn pop(inout self) -> T:
        if len(self) == 0:
            return T()
        return self.unsafe_pop()

    @always_inline
    fn pop[bnd: SpanBound = bnd](inout self, owned idx: Int) -> T:
        if len(self) == 0:
            return T()
        bnd.adjust(idx, len(self))
        return self.unsafe_pop(idx)

    # +------( Fill )------+ #
    #
    @always_inline
    fn fill(inout self, owned value: T):
        self[:].fill(value)

    @always_inline
    fn clear(inout self):
        self[:].clear()


# +----------------------------------------------------------------------------------------------+ #
# | Array Iter
# +----------------------------------------------------------------------------------------------+ #
#
@value
struct ArrayIter[
    mutability: Bool, //,
    T: Value,
    bnd: SpanBound,
    fmt: ArrayFormat,
    lifetime: AnyLifetime[mutability].type,
](Formattable, Sized, Value):
    """Span for Array.

    Parameters:
        mutability: Whether the reference to the array is mutable.
        T: The type of elements in the array.
        bnd: The boundary condition to use with subscripts.
        fmt: The default format used when printing the array.
        lifetime: The lifetime of the array.
    """

    # +------< Data >------+ #
    #
    var _src: UnsafePointer[T]
    var start: Int
    var size: Int
    var step: Int

    # +------( Lifecycle )------+ #
    #
    @always_inline
    fn __init__(inout self):
        self._src = UnsafePointer[T]()
        self.start = 0
        self.size = 0
        self.step = 1

    @always_inline
    fn __init__(inout self, src: UnsafePointer[T], owned size: Int):
        self._src = src
        self.start = 0
        self.size = size
        self.step = 1

    @always_inline
    fn __init__(inout self, src: UnsafePointer[T], owned slice: Slice):
        self._src = src
        self.start = slice.start.value()
        self.size = max(ceildiv(slice.end.value() - self.start, slice.step), 0)
        self.step = slice.step

    @always_inline
    fn __init__(inout self, ref [lifetime]src: Array[T, bnd, fmt]):
        self = ArrayIter[T, bnd, fmt, lifetime](src._data, src._size)

    @always_inline
    fn __init__(inout self, owned other: ArrayIter[T, _, _, lifetime]):
        self._src = other._src
        self.start = other.start
        self.step = other.step
        self.size = other.size

    # +------( Subscript )------+ #
    #
    @always_inline
    fn __getitem__(self, owned idx: Int) -> ref [lifetime] T:
        bnd.adjust(idx, self.size)
        return (self._src + self.start + idx * self.step)[]

    @always_inline
    fn __getitem__(self, owned slice: Slice) -> Self:
        bnd.adjust(slice, self.size)
        var start = slice.start.value() * self.step + self.start
        var step = slice.step * self.step
        var size = ceildiv(slice.end.value() - slice.start.value(), slice.step)
        return Self(self._src, start, size, step)

    # @always_inline
    # fn __setitem__(self, owned slice: Slice, value: ArrayIter[T, _, _, _]):
    #     var sliced_self = self[slice]
    #     for idx in range(min(len(sliced_self), len(value))):
    #         var a = value[idx]
    #         self[idx] = value[idx]

    # +------( Iterate )------+ #
    #
    @always_inline
    fn __iter__(self) -> Self:
        return self

    @always_inline
    fn __reversed__(self) -> Self:
        return Self(self._src, self.start + (self.size - 1) * self.step, self.size, -self.step)

    @always_inline
    fn __next__(inout self) -> Reference[T, lifetime]:
        var result = Reference[T, lifetime](self._src[self.start])
        self.start += self.step
        self.size -= 1
        return result[]

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

    # +------( Operations )------+ #
    #
    @always_inline
    fn __bool__(self) -> Bool:
        return self.size != 0

    @always_inline
    fn __len__(self) -> Int:
        return self.size

    @always_inline
    fn __eq__(self, rhs: Self) -> Bool:
        if len(self) != len(rhs):
            return False
        for idx in range(len(self)):
            if self[idx] != rhs[idx]:
                return False
        return True

    @always_inline
    fn __eq__[__: None = None](self, rhs: ArrayIter[T, _, _, _]) -> Bool:
        if len(self) != len(rhs):
            return False
        for idx in range(len(self)):
            if self[idx] != rhs[idx]:
                return False
        return True

    @always_inline
    fn __ne__(self, rhs: Self) -> Bool:
        if len(self) != len(rhs):
            return True
        for idx in range(len(self)):
            if self[idx] != rhs[idx]:
                return True
        return False

    @always_inline
    fn __ne__(self, rhs: ArrayIter[T, _, _, _]) -> Bool:
        if len(self) != len(rhs):
            return True
        for idx in range(len(self)):
            if self[idx] != rhs[idx]:
                return True
        return False

    @always_inline
    fn __contains__(self, element: T) -> Bool:
        for item in self:
            if item[] == element:
                return True
        return False

    @always_inline
    fn index(self, element: T) raises -> Int:
        for idx in range(len(self)):
            if self[idx] == element:
                return idx
        raise Error("NoValue")

    @always_inline
    fn count(self, value: T) -> Int:
        var result = 0
        for item in self:
            if item[] == value:
                result += 1
        return result

    @always_inline
    fn clear[lif: MutableLifetime, //](self: ArrayIter[T, bnd, fmt, lif]):
        self.fill(T())

    @always_inline
    fn fill[lif: MutableLifetime, //](self: ArrayIter[T, bnd, fmt, lif], value: T):
        for item in self:
            var ptr = UnsafePointer.address_of(item[])
            _del(ptr)
            _copy(ptr, value)


# +----------------------------------------------------------------------------------------------+ #
# | Array Format
# +----------------------------------------------------------------------------------------------+ #
#
@value
struct ArrayFormat:
    var beg: String
    var pad: String
    var sep: String
    var end: String
    var color: String
    var item_color: String

    @always_inline
    fn __init__(inout self):
        self = Self("", "", "", "", "", "")

    @always_inline
    fn __init__(
        inout self,
        owned beg: String,
        owned end: String,
        /,
        *,
        owned color: String = Color.none,
        owned item_color: String = Color.none,
    ):
        self = Self(beg, "", "", end, color, item_color)

    @always_inline
    fn __init__(
        inout self,
        owned beg: String,
        owned sep: String,
        owned end: String,
        /,
        *,
        owned color: String = Color.none,
        owned item_color: String = Color.none,
    ):
        self = Self(beg, "", sep, end, color, item_color)

    @always_inline
    fn __init__(
        inout self,
        owned beg: String,
        owned pad: String,
        owned sep: String,
        owned end: String,
        owned color: String = Color.none,
        owned item_color: String = Color.none,
    ):
        self.beg = beg
        self.pad = pad
        self.sep = sep
        self.end = end
        self.color = color
        self.item_color = item_color

    @always_inline
    fn __init__(inout self, string: StringLiteral):
        var span = str(string)
        self = Self(span)

    @always_inline
    fn __init__[lif: AnyLifetime[False].type](inout self, parse: StringSpan[lif]):
        var p = parse.split("\\", 6)
        if len(p) == 0:
            self = Self()
        elif len(p) == 1:
            var p0 = p[0]
            if len(p0) == 1:
                self = Self("", str(p0), "")
            elif len(p0) == 2:
                self = Self(str(p0[:1]), str(p0[-1:]))
            else:
                self = Self(str(p0[:1]), str(p0[1:-1]), str(p0[-1:]))
        elif len(p) == 2:
            self = Self(str(p[0]), str(p[1]))
        elif len(p) == 3:
            self = Self(str(p[0]), str(p[1]), str(p[2]))
        elif len(p) == 4:
            self = Self(str(p[0]), str(p[1]), str(p[2]), str(p[3]), "", "")
        elif len(p) == 5:
            self = Self(str(p[0]), str(p[1]), str(p[2]), str(p[3]), str(p[4]), "")
        elif len(p) == 6:
            self = Self(str(p[0]), str(p[1]), str(p[2]), str(p[3]), str(p[4]), str(p[5]))
        else:
            self = Self()
