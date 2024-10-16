# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova SpanBound."""

from math import iota


# +----------------------------------------------------------------------------------------------+ #
# | SpanBound
# +----------------------------------------------------------------------------------------------+ #
#
#
@register_passable("trivial")
struct SpanBound(Equatable):
    # +------[ Alias ]------+ #
    #
    alias Unsafe = SpanBound {value: 0}
    """Performs no bounds checks."""
    alias Clamp = SpanBound {value: 1}
    """Clamps the index between `0` and `size`."""
    alias Wrap = SpanBound {value: 2}
    """Wraps the index mod `size`."""
    alias Lap = SpanBound {value: 3}
    """Allows negative indexing."""

    # +------< Data >------+ #
    #
    var value: Int

    # +------( Adjust )------+ #
    #
    @always_inline
    fn adjust[context: StringLiteral = ""](self, inout idx: Int, size: Int):
        debug_assert(size > 0, "size must be greater than zero")
        if self == Self.Clamp:
            idx = min(max(idx, 0), size - 1)
        elif self == Self.Wrap:
            idx = idx % size
        elif self == Self.Lap:
            if idx < 0:
                idx += size
        debug_assert(0 <= idx < size, "index out of bounds: " + context)

    @always_inline
    fn adjust[context: StringLiteral = ""](self, inout slice: Slice, size: Int):
        var has_start = bool(slice.start)
        var has_stop = bool(slice.end)
        var step = slice.step.or_else(1)

        if not has_start:
            slice.start = 0 if step > 0 else size - 1

        if not has_stop:
            slice.end = size if step > 0 else -1

        if self == Self.Clamp:
            slice.start = min(max(slice.start.value(), 0), size - 1)
            slice.end = min(max(slice.end.value(), -step), size + step - 1)
        elif self == Self.Wrap:
            slice.start = slice.start.value() % size
            slice.end = slice.start.value() % size  #####
        elif self == Self.Lap:
            if has_start and slice.start.value() < 0:
                slice.start = slice.start.value() + size
            if has_stop and slice.end.value() < 0:
                slice.end = slice.end.value() + size

        slice.step = step

        debug_assert(0 <= slice.start.value() < size, "slice.start out of bounds: " + context)
        debug_assert(
            -step <= slice.end.value() < size + step,
            "slice.stop out of bounds: " + context,
        )

    # +------( Operations )------+ #
    #
    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value
