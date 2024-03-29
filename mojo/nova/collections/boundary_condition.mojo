from math import min, max

@register_passable("trivial")
struct BoundaryCondition(EqualityComparable):
    alias Overlap = BoundaryCondition{value: 0}
    alias Ignore = BoundaryCondition{value: 1}
    alias Clamp = BoundaryCondition{value: 2}
    alias Wrap = BoundaryCondition{value: 3}

    var value: Int

    @staticmethod
    @always_inline
    fn apply[bound: Self, context: StringLiteral = ""](index: Int, size: Int) -> Int:
        @parameter
        if bound == Self.Overlap:
            debug_assert(-size <= index < size, "index out of bounds: " + context)
            if index < 0: return index + size
            return index
        elif bound == Self.Ignore:
            debug_assert(0 <= index < size, "index out of bounds: " + context)
            return index
        elif bound == Self.Clamp:
            return min(max(index, 0), size - 1)
        elif bound == Self.Wrap:
            return index % size
        else:
            return index


    fn __eq__(self, other: BoundaryCondition) -> Bool: return self.value == other.value

    fn __ne__(self, other: BoundaryCondition) -> Bool: return self.value != other.value