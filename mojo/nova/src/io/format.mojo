# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Formatting Helper Functions."""


# +----------------------------------------------------------------------------------------------+ #
# | Write Rep
# +----------------------------------------------------------------------------------------------+ #
#
#
@always_inline
fn write_rep[WriterType: Writer, //, WritableType: Writable](inout writer: WriterType, value: WritableType, count: Int):
    for _ in range(count):
        writer.write(value)


# +----------------------------------------------------------------------------------------------+ #
# | Write Align
# +----------------------------------------------------------------------------------------------+ #
#
#
@always_inline
fn write_align[
    WriterType: Writer, //, pad: StringSpan[StaticConstantOrigin], item_color: String = Color.none
](inout writer: WriterType, span: StringSpan[_], new_len: Int):
    if len(span) > new_len:
        if new_len > 0:
            var es = max(new_len - 1, 0)
            writer.write(item_color, span[:es], "‥")
    else:
        write_rep(writer, pad, new_len - len(span))
        writer.write(item_color, span)


# +----------------------------------------------------------------------------------------------+ #
# | Write Sep
# +----------------------------------------------------------------------------------------------+ #
#
#
@always_inline
fn write_sep[WriterType: Writer, //, fmt: ArrayFormat](inout writer: WriterType, len: Int):
    writer.write(fmt.beg)
    write_rep(writer, fmt.sep, len)
    writer.write(fmt.end)


@always_inline
fn write_sep[WriterType: Writer, //, write: fn () capturing -> None, fmt: ArrayFormat](inout writer: WriterType, count: Int):
    alias sep_color = Color.clear if (
        bool(fmt.item_color) and not fmt.color
    ) else fmt.color  # remove bool()?
    writer.write(fmt.color, fmt.beg)

    for _ in range(count - 1):
        write()
        writer.write(sep_color, fmt.sep)
    if count > 0:
        write()

    writer.write(sep_color, fmt.end)
    if fmt.color:
        writer.write(Color.clear)


@always_inline
fn write_sep[
    WriterType: Writer, //, write: fn (Int) capturing -> None, fmt: ArrayFormat
](inout writer: WriterType, count: Int):
    alias sep_color = Color.clear if (
        bool(fmt.item_color) and not fmt.color
    ) else fmt.color  # remove bool()?
    writer.write(fmt.color, fmt.beg)

    var stop = count - 1
    for idx in range(stop):
        write(idx)
        writer.write(sep_color, fmt.sep)
    if count > 0:
        write(stop)

    writer.write(sep_color, fmt.end)
    if fmt.color:
        writer.write(Color.clear)


@always_inline
fn write_sep[
    WriterType: Writer, //, read: fn () capturing -> String, fmt: ArrayFormat
](inout writer: WriterType, count: Int, align: Int):
    @parameter
    @always_inline
    fn _str():
        write_align[fmt.pad, fmt.item_color](writer, read(), align)

    write_sep[_str, fmt](writer, count)


@always_inline
fn write_sep[
    WriterType: Writer, //, read: fn (Int) capturing -> String, fmt: ArrayFormat
](inout writer: WriterType, count: Int, align: Int):
    @parameter
    @always_inline
    fn _str(idx: Int):
        write_align[fmt.pad, fmt.item_color](writer, read(idx), align)

    write_sep[_str, fmt](writer, count)


@always_inline
fn write_sep[WriterType: Writer, //, fmt: ArrayFormat](inout writer: WriterType, count: Int, align: Int):
    @parameter
    @always_inline
    fn _str():
        write_rep(writer, fmt.pad, align)

    write_sep[_str, fmt](writer, count)


# struct SepFormat:
#     var _value: String
#     var _beg: Int
#     var _pad: Int
#     var _sep: Int
#     var _end: Int

#     fn __init__(inout self):
#         self._value = String()
#         self._beg = 0
#         self._pad = 0
#         self._sep = 0
#         self._end = 0

#     fn __init__(inout self, beg: StringSpan[_], end: StringSpan[_]):
#         self._value = String.format_sequence(beg, end)
#         self._beg = len(beg)
#         self._pad = self._beg
#         self._sep = self._pad
#         self._end = self._sep + len(end)

#     fn __init__(inout self, beg: StringSpan[_], sep: StringSpan[_], end: StringSpan[_]):
#         self._value = String.format_sequence(beg, sep, end)
#         self._beg = len(beg)
#         self._pad = self._beg
#         self._sep = self._pad + len(sep)
#         self._end = self._sep + len(end)

#     fn __init__(inout self, beg: StringSpan[_], pad: StringSpan[_], sep: StringSpan[_], end: StringSpan[_]):
#         self._value = String.format_sequence(beg, pad, sep, end)
#         self._beg = len(beg)
#         self._pad = self._beg + len(pad)
#         self._sep = self._pad + len(sep)
#         self._end = self._sep + len(end)

#     fn __init__(inout self, parse: StringSpan[_]):
#         var data = List[UInt8](capacity=len(parse))
#         self._beg = 0
#         self._pad = 0
#         self._sep = 0
#         self._end = 0
#         var ptr = parse.unsafe_ptr()
#         var count = 0
#         var parse_len = len(parse)

#         @parameter
#         fn _next_member(inout member: Int) -> Bool:
#             var char: UInt8
#             while count < parse_len:
#                 char = ptr[count]
#                 count += 1
#                 if char == ord("\\"):
#                     member = data.size
#                     return True
#                 data.append(char)
#             member = data.size
#             return False

#         if not _next_member(self._beg):
#             if data.size == 1:
#                 self._sep = 1
#                 self._end = 1
#             elif data.size == 2:
#                 self._beg = 1
#                 self._pad = 1
#                 self._sep = 1
#                 self._end = 2
#             elif data.size >= 3:
#                 self._beg = 1
#                 self._pad = 1
#                 self._sep = count - 1
#                 self._end = count
#         elif not _next_member(self._pad):
#             self._end = self._pad
#             self._pad = self._beg
#             self._sep = self._beg
#         elif not _next_member(self._sep):
#             self._end = self._sep
#             self._sep = self._pad
#             self._pad = self._beg
#         else:
#             _ =_next_member(self._end)

#         data.append(0)
#         self._value = data^

#     @always_inline
#     fn __copyinit__(inout self, other: Self):
#         self._value = other._value
#         self._beg = other._beg
#         self._pad = other._pad
#         self._sep = other._sep
#         self._end = other._end

#     @always_inline
#     fn __moveinit__(inout self, owned other: Self):
#         self._value = other._value^
#         self._beg = other._beg
#         self._pad = other._pad
#         self._sep = other._sep
#         self._end = other._end

#     @always_inline
#     fn __bool__(self) -> Bool:
#         return self._value

#     @always_inline
#     fn __getattr__[name: StringLiteral](self) -> StringSpan[__origin_of(self)]:
#         var ptr = self._value.unsafe_ptr()
#         @parameter
#         if name == "beg":
#             return StringSpan[__origin_of(self)](ptr, self._beg)
#         elif name == "pad":
#             return StringSpan[__origin_of(self)]((ptr + self._beg), self._pad - self._beg)
#         elif name == "sep":
#             return StringSpan[__origin_of(self)]((ptr + self._pad), self._sep - self._pad)
#         elif name == "end":
#             return StringSpan[__origin_of(self)]((ptr + self._sep), self._end - self._sep)
#         else:
#             return StringSpan[__origin_of(self)](ptr, 0)


# struct BoxFormat:
#     var top: SepFormat
#     var div: SepFormat
#     var mid: SepFormat
#     var bot: SepFormat

#     @always_inline
#     fn __init__(inout self, mid: SepFormat):
#         self = Self(SepFormat(), SepFormat(), mid, SepFormat())

#     @always_inline
#     fn __init__(inout self, top: SepFormat, bot: SepFormat):
#         self = Self(top, SepFormat(), SepFormat(), bot)

#     @always_inline
#     fn __init__(inout self, top: SepFormat, mid: SepFormat, bot: SepFormat):
#         self = Self(top, SepFormat(), mid, bot)

#     fn __init__(inout self, top: SepFormat, div: SepFormat, mid: SepFormat, bot: SepFormat):
#         self.top = top
#         self.div = div
#         self.mid = mid
#         self.bot = bot

#     fn __init__(inout self, parse: StringSpan[_]):
#         self.top = SepFormat()
#         self.mid = SepFormat()
#         self.bot = SepFormat()
#         var ptr = parse.unsafe_ptr()
#         var start = 0
#         var count = 0
#         var parse_len = len(parse)

#         @parameter
#         fn _next_member(inout member: SepFormat) -> Bool:
#             while count < parse_len:
#                 var char = ptr[count]
#                 count += 1
#                 if char != ord("\n"):
#                     member = __type_of(parse)(ptr + start, (count - 1) - start)
#                     start = count
#                     return True
#             return False

#         if not _next_member(self.top):
#             self.mid = self.top^
#             self.top = SepFormat()
#         elif not _next_member(self.mid):
#             self.bot = self.mid^
#             self.mid = SepFormat()
#         else:
#             _ = _next_member(self.bot)
