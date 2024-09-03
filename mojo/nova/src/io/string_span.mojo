# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova StringSpan."""

from memory import memcpy
from utils import Span


# +----------------------------------------------------------------------------------------------+ #
# | StringSpan
# +----------------------------------------------------------------------------------------------+ #
#
#
@value
struct StringSpan[is_mutable: Bool, //, lifetime: AnyLifetime[is_mutable].type](Value):
    """String Span."""

    # +------< Data >------+ #
    #
    var _span: Span[UInt8, lifetime]

    # +------( Lifecycle )------+ #
    #
    @always_inline
    fn __init__(inout self):
        self._span = Span[UInt8, lifetime](unsafe_ptr=UnsafePointer[UInt8](), len=0)

    @always_inline
    fn __init__(inout self, owned unsafe_from_utf8: Span[UInt8, lifetime]):
        self._span = unsafe_from_utf8^

    @always_inline
    fn __init__(inout self, ptr: UnsafePointer[UInt8], len: Int):
        self._span = Span[UInt8, lifetime](unsafe_ptr=ptr, len=len)

    @always_inline
    fn __init__(inout self, ref [lifetime]string: String):
        self._span = Span[UInt8, lifetime](unsafe_ptr=string.unsafe_ptr(), len=len(string))

    @always_inline
    fn __init__(inout self, ref [lifetime]string: StringLiteral):
        self._span = Span[UInt8, lifetime](unsafe_ptr=string.unsafe_ptr(), len=len(string))

    # +------( Operations )------+ #
    #
    fn __str__(self) -> String:
        var length: Int = len(self.as_bytes_slice())
        var buffer = String._buffer_type()
        # +1 for null terminator, initialized to 0
        buffer.resize(length + 1, 0)
        memcpy(
            dest=buffer.data,
            src=self.as_bytes_slice().unsafe_ptr(),
            count=length,
        )
        return buffer^

    fn __len__(self) -> Int:
        return len(self._span)

    fn __bool__(self) -> Bool:
        return self.__len__() > 0

    fn __eq__(self, other: Self) -> Bool:
        if len(self._span) != len(other._span):
            return False
        for idx in range(len(self._span)):
            if self._span[idx] != other._span[idx]:
                return False
        return True

    fn __eq__(self, other: StringSpan[_]) -> Bool:
        if len(self._span) != len(other._span):
            return False
        for idx in range(len(self._span)):
            if self._span[idx] != other._span[idx]:
                return False
        return True

    fn _ne(self, other: StringSpan[_]) -> Bool:
        if len(self._span) != len(other._span):
            return True
        for idx in range(len(self._span)):
            if self._span[idx] != other._span[idx]:
                return True
        return False

    fn __ne__(self, other: Self) -> Bool:
        if len(self._span) != len(other._span):
            return True
        for idx in range(len(self._span)):
            if self._span[idx] != other._span[idx]:
                return True
        return False

    fn __ne__(self, other: StringSpan[_]) -> Bool:
        if len(self._span) != len(other._span):
            return True
        for idx in range(len(self._span)):
            if self._span[idx] != other._span[idx]:
                return True
        return False

    fn split[
        lif: AnyLifetime[False].type
    ](self: StringSpan[lif], sep: String, max: Int) -> List[StringSpan[lif]]:
        var result = List[StringSpan[lif]](capacity=8)
        var remaining = self

        @parameter
        fn _stop() -> Bool:
            return len(result) >= max

        _split[_stop](sep, result, remaining)
        return result

    fn split[
        lif: AnyLifetime[False].type
    ](self: StringSpan[lif], sep: String, stop: String) -> List[StringSpan[lif]]:
        var result = List[StringSpan[lif]](capacity=8)
        var remaining = self

        @parameter
        fn _stop() -> Bool:
            return remaining[: len(stop)] == stop

        _split[_stop](sep, result, remaining)
        return result

    fn split[
        lif: AnyLifetime[False].type
    ](self: StringSpan[lif], sep: String) -> List[StringSpan[lif]]:
        var result = List[StringSpan[lif]](capacity=8)
        var remaining = self

        @parameter
        fn _stop() -> Bool:
            return False

        _split[_stop](sep, result, remaining)
        return result

    @always_inline
    fn __getitem__(self, owned slice: Slice) -> Self:
        SpanBound.Lap.adjust(slice, len(self._span))
        var ptr = self._span._data + slice.start.value()
        return Span[UInt8, lifetime](
            unsafe_ptr=ptr, len=(slice.end.value() - slice.start.value()) // slice.step
        )

    @always_inline
    fn format_to(self, inout writer: Formatter):
        writer._write_func(writer._write_func_arg, self._strref_dangerous())

    @always_inline
    fn as_bytes_slice(self) -> Span[UInt8, lifetime]:
        return self._span

    @always_inline
    fn unsafe_ptr(self) -> UnsafePointer[UInt8]:
        return self._span.unsafe_ptr()

    @always_inline
    fn _byte_length(self) -> Int:
        return len(self.as_bytes_slice())

    fn _strref_dangerous(self) -> StringRef:
        return StringRef(self.unsafe_ptr(), self._byte_length())

    fn _strref_keepalive(self):
        pass


# +----------------------------------------------------------------------------------------------+ #
# | Split
# +----------------------------------------------------------------------------------------------+ #
#
#
fn _split[
    lifetime: AnyLifetime[False].type, //, stop_condition: fn () capturing -> Bool
](sep: String, inout result: List[StringSpan[lifetime]], inout remaining: StringSpan[lifetime]):
    var current = StringSpan[lifetime](remaining._span._data, 0)

    while True:
        if remaining[: len(sep)] == sep:
            result += current
            remaining._span._data += len(sep)
            remaining._span._len -= len(sep)
            current = StringSpan[lifetime](remaining._span._data, 0)
            if stop_condition():
                return
        if len(remaining) <= len(sep):
            break
        remaining._span._data += 1
        remaining._span._len -= 1
        current._span._len += 1

    current._span._len += len(remaining)
    result += current
