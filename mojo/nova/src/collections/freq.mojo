# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Frequency."""

from collections.dict import Dict, DictEntry, _DictEntryIter


# +----------------------------------------------------------------------------------------------+ #
# | Freq
# +----------------------------------------------------------------------------------------------+ #
#
struct Freq[T: StringableKeyElement](Writable, Sized, Boolable, Value, Hashable):
    """Frequency."""

    # +------< Data >------+ #
    #
    var total: Int
    var _data: Dict[T, Int]

    # +------( Lifecycle )------+ #
    #
    fn __init__(inout self):
        self.total = 0
        self._data = Dict[T, Int]()

    fn __copyinit__(inout self, other: Self):
        self.total = other.total
        self._data = other._data

    fn __moveinit__(inout self, owned other: Self):
        self.total = other.total
        self._data = other._data^

    # +------( Subscript )------+ #
    #
    fn __getitem__(self, key: T) -> Int:
        return self._data.find(key).or_else(0)

    fn __setitem__(inout self, key: T, freq: Int):
        if freq < 0:
            print("oh no", str(key), freq)
        if freq > 0:
            self._data[key] = freq
        else:
            self.discard(key)

    fn __iter__(ref [_]self: Self) -> _DictEntryIter[T, Int, __origin_of(self._data)]:
        return _DictEntryIter[T, Int, __origin_of(self._data)](0, 0, self._data)

    @always_inline
    fn discard(inout self, key: T):
        try:
            _ = self._data.pop(key)
        except:
            pass

    # +------( Format )------+ #
    #
    @always_inline
    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return self.__str__()

    fn write_to[WriterType: Writer](self, inout writer: WriterType):
        writer.write(str(self.total), " {")
        var written = 0
        for item in self:
            writer.write(str(item[].key), ": ", str(item[].value))
            if written < len(self) - 1:
                writer.write(", ")
            written += 1
        writer.write("}")

    # +------( Unary )------+ #
    #
    @always_inline
    fn __len__(self) -> Int:
        return self._data.__len__()

    @always_inline
    fn __bool__(self) -> Bool:
        return self._data.__bool__()

    fn __hash__(self) -> UInt:
        var hash_value = 0
        for e in self:
            hash_value ^= hash(e[].key) + e[].value
        return hash_value

    # +------( Comparison )------+ #
    #
    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        if len(self) != len(other):
            return False
        for item in self:
            if item[].value != other[item[].key]:
                return False
        return True

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    @always_inline
    fn __contains__(self, item: T) -> Bool:
        return self[item] != 0

    # +------( Addition )------+ #
    #
    @always_inline
    fn __add__(self, rhs: T) -> Self:
        var result = self
        result += rhs
        return result

    @always_inline
    fn __add__(self, rhs: DictEntry[T, Int]) -> Self:
        var result = self
        result += rhs
        return result

    @always_inline
    fn __add__(self, rhs: Self) -> Self:
        var result = self
        result += rhs
        return result

    @always_inline
    fn __iadd__(inout self, rhs: T):
        self[rhs] += 1

    @always_inline
    fn __iadd__(inout self, rhs: DictEntry[T, Int]):
        self[rhs.key] += rhs.value

    @always_inline
    fn __iadd__(inout self, rhs: Self):
        for item in rhs:
            self += item[]

    # +------( Subtract )------+ #
    #
    @always_inline
    fn __sub__(self, rhs: T) -> Self:
        var result = self
        result -= rhs
        return result

    @always_inline
    fn __sub__(self, rhs: DictEntry[T, Int]) -> Self:
        var result = self
        result -= rhs
        return result

    @always_inline
    fn __sub__(self, rhs: Self) -> Self:
        var result = self
        result -= rhs
        return result

    @always_inline
    fn __isub__(inout self, rhs: T):
        self[rhs] -= 1

    @always_inline
    fn __isub__(inout self, rhs: DictEntry[T, Int]):
        self[rhs.key] -= rhs.value

    @always_inline
    fn __isub__(inout self, rhs: Self):
        for item in rhs:
            self -= item[]

    @always_inline
    fn clear(inout self):
        self.total = 0
        try:
            while True:
                _ = self._data.popitem()
        except:
            pass
