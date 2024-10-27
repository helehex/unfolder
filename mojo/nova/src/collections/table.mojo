# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Table."""

from collections import Optional
from ..memory import _init, _copy, _move, _take, _del
from ..io import Box, Color
from .array import ArrayIter


# +----------------------------------------------------------------------------------------------+ #
# | Table
# +----------------------------------------------------------------------------------------------+ #
#
struct Table[
    T: Value,
    bnd: Tuple[SpanBound, SpanBound] = (SpanBound.Lap, SpanBound.Lap),
    fmt: TableFormat = TableFormat(),
](Writable, Value):
    """A heap allocated table.

    Parameters:
        T: The type of elements in the table.
        bnd: The boundary condition to use with subscripts.
        fmt: The default format used when printing the table.
    """

    # +------< Data >------+ #
    #
    var _data: UnsafePointer[T]
    var _cols: Int
    var _rows: Int

    # +------( Lifecycle )------+ #
    #
    @always_inline
    fn __init__(inout self):
        """Creates a null array with zero size."""
        self._data = UnsafePointer[T]()
        self._cols, self._rows = 0, 0

    @always_inline
    fn __init__[clear: Bool = True](inout self, cols: Int, rows: Int):
        """Creates a new array and fills it with default values."""
        var size = cols * rows
        self._data = UnsafePointer[T].alloc(size)
        self._cols, self._rows = cols, rows

        @parameter
        if clear:
            _init(self._data, size)

    @always_inline
    fn __init__(inout self, cols: Int, rows: Int, *, fill: T):
        self.__init__[False](cols=cols, rows=rows)
        for idx in range(cols * rows):
            _copy(self._data + idx, fill)

    @always_inline
    fn __init__(inout self, cols: Int, rows: Int, *, rule: fn (Int, Int) -> T):
        self.__init__[False](cols=cols, rows=rows)
        var idx = 0
        for y in range(rows):
            for x in range(cols):
                _move(self._data + idx, rule(x, y))
                idx += 1

    @always_inline
    fn __copyinit__(inout self, other: Self):
        if other._data:
            self.__init__[False](other._cols, other._rows)
            _copy(self._data, other._data, self._cols * self._rows)
        else:
            self = Self()

    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        self._data = other._data
        self._cols = other._cols
        self._rows = other._rows

    @always_inline
    fn __del__(owned self):
        """Delete the items in this table."""
        if self._data:
            _del(self._data, self._cols * self._rows)
            self._data.free()

    # +------( Subscript )------+ #
    #
    @always_inline
    fn __getitem__(ref [_]self, col: Int, row: Int) -> ref [self] T:
        return (self._data + (row * self._cols + col))[]

    @always_inline
    fn __getitem__(ref [_]self, ind: Ind2) -> ref [self] T:
        return self[ind[0], ind[1]]

    @always_inline
    fn __getitem__(
        ref [_]self, owned col: Slice, owned row: Int
    ) -> ArrayIter[T, bnd[0], fmt.to_row_fmt(), __origin_of(self)]:
        bnd[0].adjust(col, self._cols)
        bnd[1].adjust(row, self._rows)
        var idx = row * self._cols
        var start = idx + col.start.value()
        var stop = idx + col.end.value()
        return ArrayIter[T, bnd[0], fmt.to_row_fmt(), __origin_of(self)](
            self._data, Slice(start, stop, col.step)
        )

    @always_inline
    fn __getitem__(
        ref [_]self, owned col: Int, owned row: Slice
    ) -> ArrayIter[T, bnd[1], fmt.to_col_fmt(), __origin_of(self)]:
        bnd[0].adjust(col, self._cols)
        bnd[1].adjust(row, self._rows)
        var start = row.start.value() * self._cols + col
        var stop = row.end.value() * self._cols + col
        var step = self._cols * row.step.value()
        return ArrayIter[T, bnd[1], fmt.to_col_fmt(), __origin_of(self)](
            self._data, Slice(start, stop, step)
        )

    @always_inline
    fn row(ref [_]self, idx: Int) -> ArrayIter[T, bnd[0], fmt.to_row_fmt(), __origin_of(self)]:
        var start = idx * self._cols
        var stop = start + self._cols
        return ArrayIter[T, bnd[0], fmt.to_row_fmt(), __origin_of(self)](
            self._data, Slice(start, stop)
        )

    @always_inline
    fn col(ref [_]self, idx: Int) -> ArrayIter[T, bnd[1], fmt.to_col_fmt(), __origin_of(self)]:
        var start = idx
        var stop = self._cols * self._rows
        var step = self._cols
        return ArrayIter[T, bnd[1], fmt.to_col_fmt(), __origin_of(self)](
            self._data, Slice(start, stop, step)
        )

    # +------( Format )------+ #
    #
    @always_inline
    fn __str__(self) -> String:
        return String.write(self)

    @always_inline
    fn to_string[fmt: TableFormat = fmt](self) -> String:
        var result: String = ""
        self.write_to[fmt=fmt](result)
        return result

    @always_inline
    fn to_string[fmt: TableFormat = fmt](self, align: Int) -> String:
        var result: String = ""
        self.write_to[fmt=fmt](result, align)
        return result

    @always_inline
    fn _get_item_align(self) -> Int:
        var longest = len(str(self._cols - 1))
        for idx in range(self._cols * self._rows):
            longest = max(longest, len(str(self._data[idx])))
        return longest

    @always_inline
    fn _get_tbl_pad[fmt: TableFormat = fmt](self) -> Int:
        var result = len(str(self._rows - 1)) - 1

        @parameter
        if fmt.show_col_idx:
            result = max(result, len(fmt.lbl))
        return result

    @always_inline
    fn write_to[WriterType: Writer, //, fmt: TableFormat = fmt](self, inout writer: WriterType):
        self.write_to[fmt=fmt](writer, self._get_item_align())

    @always_inline
    fn write_to[
        WriterType: Writer, //, fmt: TableFormat = fmt
    ](self, inout writer: WriterType, align: Int):
        var pad = self._get_tbl_pad[fmt]()

        if self._cols <= 0 or self._rows <= 0:

            @parameter
            if bool(fmt.lbl) and fmt.show_col_idx and fmt.show_row_idx:  # remove bool()?
                writer.write(fmt.box_color, Box.rb)
                write_rep(writer, Box.h, len(fmt.lbl) + 2)
                writer.write(Box.lb + "\n" + Box.v + " ")
                writer.write(fmt.lbl_color, fmt.lbl, fmt.box_color)
                writer.write(" " + Box.v + "\n" + Box.rt)
                write_rep(writer, Box.h, len(fmt.lbl) + 2)
                writer.write(Box.lt + Color.clear)
            else:
                writer.write(fmt.box_color)
                writer.write(Box.rb + Box.h + Box.lb + "\n" + Box.rt + Box.h + Box.lt + Color.clear)
            return

        @parameter
        if fmt.show_col_idx:

            @parameter
            if fmt.show_row_idx:
                write_sep[ArrayFormat(Box.rb, Box.h, "", "", fmt.box_color)](writer, 1, pad + 2)
                write_sep[ArrayFormat(Box.hB, Box.h, Box.hb, Box.lb + "\n", fmt.box_color)](
                    writer, self._cols, align
                )

                @parameter
                @always_inline
                fn _str_lbl() -> String:
                    return str(fmt.lbl)

                write_sep[
                    _str_lbl, ArrayFormat(Box.v + " ", " ", "", " ", fmt.box_color, fmt.lbl_color)
                ](writer, 1, pad)
            else:
                write_sep[ArrayFormat(Box.rB, Box.h, Box.hb, Box.lb + "\n", fmt.box_color)](
                    writer, self._cols, align
                )

            @parameter
            @always_inline
            fn _str_col_idx(idx: Int) -> String:
                return str(idx)

            write_sep[
                _str_col_idx,
                ArrayFormat(Box.V, " ", Box.v, Box.v + "\n", fmt.box_color, fmt.idx_color),
            ](writer, self._cols, align)

            @parameter
            if fmt.show_row_idx:
                write_sep[ArrayFormat(Box.Rv, Box.H, "", "", fmt.box_color)](writer, 1, pad + 2)
                write_sep[ArrayFormat(Box.HV, Box.H, Box.Hv, Box.Lv + "\n", fmt.box_color)](
                    writer, self._cols, align
                )
            else:
                write_sep[ArrayFormat(Box.RV, Box.H, Box.Hv, Box.Lv + "\n", fmt.box_color)](
                    writer, self._cols, align
                )
        else:

            @parameter
            if fmt.show_row_idx:
                write_sep[ArrayFormat(Box.Rb, Box.H, "", "", fmt.box_color)](writer, 1, pad + 2)
                write_sep[ArrayFormat(Box.HB, Box.H, Box.Hb, Box.Lb + "\n", fmt.box_color)](
                    writer, self._cols, align
                )
            else:
                write_sep[ArrayFormat(Box.RB, Box.H, Box.Hb, Box.Lb + "\n", fmt.box_color)](
                    writer, self._cols, align
                )

        @parameter
        @always_inline
        fn _str_rows(idx: Int):
            @parameter
            if fmt.show_row_idx:

                @parameter
                @always_inline
                fn _str_row_idx(_idx: Int) -> String:
                    return str(idx)

                write_sep[
                    _str_row_idx,
                    ArrayFormat(
                        fmt.box_color + Box.v,
                        fmt.item_pad,
                        "",
                        fmt.box_color + fmt.item_pad,
                        "",
                        fmt.idx_color,
                    ),
                ](writer, 1, pad + 1)

            self.row(idx).write_to[
                fmt = ArrayFormat(Box.V, fmt.item_pad, Box.v, Box.v, fmt.box_color, fmt.item_color)
            ](writer, align)

        write_sep[_str_rows, ArrayFormat("", fmt.item_pad, "\n", "\n", fmt.box_color)](
            writer, self._rows
        )

        @parameter
        if fmt.show_row_idx:
            write_sep[ArrayFormat(Box.rt, Box.h, "", "", fmt.box_color)](writer, 1, pad + 2)
            write_sep[ArrayFormat(Box.hT, Box.h, Box.ht, Box.lt, fmt.box_color)](
                writer, self._cols, align
            )
        else:
            write_sep[ArrayFormat(Box.rT, Box.h, Box.ht, Box.lt, fmt.box_color)](
                writer, self._cols, align
            )

    # +------( Operations )------+ #
    #
    @always_inline
    fn __bool__(self) -> Bool:
        return self._cols != 0 and self._rows != 0

    @always_inline
    fn __eq__(self, rhs: Self) -> Bool:
        return self.__eq__[None](rhs)

    @always_inline
    fn __eq__[__: None = None](self, rhs: Table[T, _, _]) -> Bool:
        if self._cols != rhs._cols or self._rows != rhs._rows:
            return False
        var size = self._cols * self._rows
        for idx in range(size):
            if (self._data + idx)[] != (rhs._data + idx)[]:
                return False
        return True

    @always_inline
    fn __ne__(self, rhs: Self) -> Bool:
        return self.__ne__[None](rhs)

    @always_inline
    fn __ne__[__: None = None](self, rhs: Table[T, _, _]) -> Bool:
        if self._cols != rhs._cols or self._rows != rhs._rows:
            return True
        var size = self._cols * self._rows
        for idx in range(size):
            if (self._data + idx)[] != (rhs._data + idx)[]:
                return True
        return False

    @always_inline
    fn _resize(self, cols: Int, rows: Int) -> Table[T, bnd, fmt]:
        var result: Self
        result.__init__[False](cols, rows)
        var col_dif = cols - self._cols
        var row_dif = rows - self._rows
        var dst = result._data
        var src = self._data

        @parameter
        @always_inline
        fn _copy_rows(count: Int):
            if col_dif > 0:
                for _ in range(count):
                    _copy(dst, src, self._cols)
                    dst += self._cols
                    src += self._cols
                    _init(dst, col_dif)
                    dst += col_dif
            else:
                for _ in range(count):
                    _copy(dst, src, cols)
                    dst += cols
                    src += self._cols

        if row_dif > 0:
            _copy_rows(self._rows)
            _init(dst, cols * row_dif)
        else:
            _copy_rows(rows)

        return result

    @always_inline
    fn resize(inout self, cols: Int, rows: Int):
        self = self._resize(cols, rows)


# +----------------------------------------------------------------------------------------------+ #
# | Table Format
# +----------------------------------------------------------------------------------------------+ #
#
struct TableFormat:
    var lbl: StringLiteral
    var lbl_color: StringLiteral
    var idx_color: StringLiteral
    var box_color: StringLiteral
    var item_color: StringLiteral
    var item_pad: StringLiteral
    var show_col_idx: Bool
    var show_row_idx: Bool

    @always_inline
    fn __init__(
        inout self,
        owned lbl: StringLiteral = " ",
        owned lbl_color: StringLiteral = Color.none,
        owned idx_color: StringLiteral = Color.none,
        owned box_color: StringLiteral = Color.none,
        owned item_color: StringLiteral = Color.none,
        owned item_pad: StringLiteral = " ",
        owned show_col_idx: Bool = True,
        owned show_row_idx: Bool = True,
    ):
        self.lbl = lbl
        self.lbl_color = lbl_color
        self.idx_color = idx_color
        self.box_color = box_color
        self.item_color = item_color
        self.item_pad = item_pad
        self.show_col_idx = show_col_idx
        self.show_row_idx = show_row_idx

    # @always_inline
    # fn __init__(
    #     inout self,
    #     owned lbl: Variant[String, StringRef, StringLiteral] = " ",
    #     owned lbl_color: Variant[String, StringRef, StringLiteral] = Color.none,
    #     owned idx_color: Variant[String, StringRef, StringLiteral] = Color.none,
    #     owned box_color: Variant[String, StringRef, StringLiteral] = Color.none,
    #     owned item_color: Variant[String, StringRef, StringLiteral] = Color.none,
    #     owned item_pad: Variant[String, StringRef, StringLiteral] = " ",
    #     owned show_col_idx: Bool = False,
    #     owned show_row_idx: Bool = False,
    # ):
    #     self.value = String()

    #     @parameter
    #     @always_inline
    #     fn _append(inout value: Variant[String, StringRef, StringLiteral]):
    #         if value.isa[String]():
    #             self.value += value.unsafe_get[String]()[]
    #         elif value.isa[StringRef]():
    #             self.value += value.unsafe_get[StringRef]()[]

    #     _append(lbl)
    #     _append(lbl_color)
    #     _append(idx_color)
    #     _append(box_color)
    #     _append(item_color)
    #     _append(item_pad)

    #     var ptr = self.value.unsafe_uint8_ptr()
    #     var count = 0

    #     @parameter
    #     @always_inline
    #     fn _get_ref(inout value: Variant[String, StringRef, StringLiteral]) -> StringRef:
    #         if value.isa[String]():
    #             var string = value.unsafe_get[String]()[]
    #             count += len(string)
    #             return StringRef(ptr + count, len(string))
    #         elif value.isa[StringRef]():
    #             var string = value.unsafe_get[StringRef]()[]
    #             count += len(string)
    #             return StringRef(ptr + count, len(string))
    #         return value.unsafe_get[StringLiteral]()[]

    #     self.lbl = _get_ref(lbl)
    #     self.lbl_color = _get_ref(lbl_color)
    #     self.idx_color = _get_ref(idx_color)
    #     self.box_color = _get_ref(box_color)
    #     self.item_color = _get_ref(item_color)
    #     self.item_pad = _get_ref(item_pad)
    #     self.show_col_idx = show_col_idx
    #     self.show_row_idx = show_row_idx

    @always_inline
    fn to_row_fmt(self) -> ArrayFormat:
        return ArrayFormat(Box.v, "", Box.v, Box.v, self.box_color, self.item_color)

    @always_inline
    fn to_col_fmt(self) -> ArrayFormat:
        return ArrayFormat(
            Box.v, self.item_pad, Box.v + "\n" + Box.v, Box.v, self.box_color, self.item_color
        )

    @staticmethod
    fn icey(
        lbl: StringLiteral = "Icey", show_col_idx: Bool = True, show_row_idx: Bool = True
    ) -> Self:
        return Self(
            lbl, Color.clear, Color.none, Color.cyan, Color.clear, " ", show_col_idx, show_row_idx
        )
