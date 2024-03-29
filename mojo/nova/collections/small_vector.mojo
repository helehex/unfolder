#------ Small Vector ------#
#---
@register_passable("trivial")
struct SmallVector[T: AnyRegType, capacity: Int, bound: BoundaryCondition = BoundaryCondition.Ignore](Sized, Boolable, EqualityComparable):
    """
    A small register passable vector with a fixed capacity and dynamic size.
    """

    #------< Data >------#
    #
    var _value: StaticTuple[T, capacity]
    var _size: Int


    #------( Initialization )------#
    #
    fn __init__(inout self):
        self._value = StaticTuple[T, capacity]()
        self._size = 0

    fn __init__(inout self, *items: T):
        self._value = StaticTuple[T, capacity]()
        self._size = len(items)
        for i in range(self._size): self._value[i] = items[i]


    #------( Get / Set )------#
    #
    fn __getitem__(self, index: Int) -> T:
        return self._value[BoundaryCondition.apply[bound](index, self._size)]

    fn __setitem__(inout self, index: Int, item: T):
        self._value[BoundaryCondition.apply[bound](index, self._size)] = item


    #------( Operations )------#
    #
    fn __str__(self) -> String:
        # only works for int vector, multi traits might help?
        var result: String = ""
        var end: Int = len(self) - 1
        for i in range(end): result += str(rebind[Int](self[i])) + "\n"
        return result + str(rebind[Int](self[end]))

    fn __len__(self) -> Int:
        return self._size

    fn __bool__(self) -> Bool:
        return self._size != 0

    @always_inline
    fn __eq__[other_capacity: Int = capacity, other_bound: BoundaryCondition = bound](self, other: SmallVector[T, other_capacity, other_bound]) -> Bool:
        if self._size != other._size: return False
        var _self: StaticTuple[T, capacity] = self._value
        var _other: StaticTuple[T, other_capacity] = other._value
        var sp = bitcast[Scalar[DType.int8]](int(Pointer[_self.type].address_of(_self.array)))
        var op = bitcast[Scalar[DType.int8]](int(Pointer[_other.type].address_of(_other.array)))
        var result = memcmp(sp, op, self._size * alignof[T]()) == 0
        return result

    @always_inline
    fn __ne__[other_capacity: Int = capacity, other_bound: BoundaryCondition = bound](self, other: SmallVector[T, other_capacity, other_bound]) -> Bool:
        return not (self == other)

    fn append(inout self, item: T):
        debug_assert(self._size < capacity, "not enough capacity")
        @parameter
        if bound != BoundaryCondition.Ignore:
            if self._size >= capacity: return
        self._value[self._size] = item
        self._size += 1

    fn pop(inout self) -> T:
        debug_assert(self._size > 0, "already empty")
        @parameter
        if bound != BoundaryCondition.Ignore:
            if self._size <= 0:
                return rebind[T, Int](0)
        self._size -= 1
        return self._value[self._size]
        
        