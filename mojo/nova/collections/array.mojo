#------ Array ------#
#---
struct Array[T: AnyRegType, bound: BoundaryCondition = BoundaryCondition.Ignore](Sized, Boolable, EqualityComparable):
    """
    A simple heap allocated, reference counted array.
    """

    #------< Data >------#
    #
    var _size: Int
    var _rc: Pointer[Int]
    var _data: Pointer[T]


    #------( Lifetime )------#
    #
    @always_inline
    fn __init__(inout self):
        """Creates a null array with zero size."""
        self._size = 0
        self._data = Pointer[T].get_null()
        self._rc = Pointer[Int].alloc(1)
        self._rc.store(0)
    
    @always_inline
    fn __init__(inout self, *, size: Int):
        """Creates a new array with the given size and filled with zeros."""
        self._size = size
        self._data = Pointer[T].alloc(self._size)
        self._rc = Pointer[Int].alloc(1)
        self._rc.store(0)
        self.clear()
        
    @always_inline
    fn __init__(inout self, *, size: Int, fill: T):
        """Creates a new array with the given size and filled with a value."""
        self._size = size
        self._data = Pointer[T].alloc(self._size)
        self._rc = Pointer[Int].alloc(1)
        self._rc.store(0)
        self.fill(fill)
    
    @always_inline
    fn __init__(inout self, elements: VariadicList[T]):
        """Creates a new array with the given elements."""
        self._size = len(elements)
        self._data = Pointer[T].alloc(self._size)
        self._rc = Pointer[Int].alloc(1)
        self._rc.store(0)
        for i in range(self._size): self[i] = elements[i]

    @always_inline
    fn __init__(inout self, *elements: T):
        """Creates a new array with the given elements."""
        self = Self(elements)

    @always_inline
    fn __init__(inout self, *, owned copy: Self): # owned array for the case of self reference
        """Creates a `copy` of another array."""
        self._size = copy._size
        self._data = Pointer[T].alloc(self._size)
        self._rc = Pointer[Int].alloc(1)
        self._rc.store(0)
        self.copy(copy, end = copy._size)

    @always_inline
    fn __init__(inout self, *, owned copy: Self, size: Int, end: Int, start: Int = 0, offset: Int = 0): # owned array for the case of self reference
        """Creates a `copy` from the `start` to the `end` of another array, with an `offset`, and pads extra `size` with zeros."""
        self._size = size
        self._data = Pointer[T].alloc(self._size)
        self._rc = Pointer[Int].alloc(1)
        self._rc.store(0)
        self.clear(0, offset)
        self.copy(copy, start = start, end = end, offset = offset)
        self.clear((end - start) + offset, self._size)
        
    @always_inline
    fn __init__(inout self, append: VariadicList[T], *, owned copy: Self): # owned array for the case of self reference
        """Creates a new array by appending values onto a copy of an existing array."""
        self._size = copy._size + len(append)
        self._data = Pointer[T].alloc(self._size)
        self._rc = Pointer[Int].alloc(1)
        self._rc.store(0)
        self.copy(copy, end = copy._size)
        for i in range(len(append)): self[i + copy._size] = append[i]

    @always_inline
    fn __init__(inout self, *append: T, owned copy: Self): # owned array for the case of self reference
        """Creates a new array by appending values onto a copy of an existing array."""
        self = Self(append, copy)
    
    @always_inline
    fn __copyinit__(inout self, other: Self):
        (self._size, self._rc, self._data) = (other._size, other._rc, other._data)
        self._rc.store(self._rc.load() + 1)
    
    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        (self._size, self._rc, self._data) = (other._size, other._rc, other._data)

    @always_inline
    fn _get_rc(self) -> Int:
        return self._rc.load()

    @always_inline
    fn __del__(owned self):
        var rc = self._rc.load()
        if rc == 0:
            self._rc.free()
            self._data.free()
        else:
            self._rc.store(rc - 1)


    #------( Get / Set )------#
    #
    @always_inline
    fn __getitem__(self, index: Int) -> T:
        """Gets the value at the provided index."""
        return self._data.load(BoundaryCondition.apply[bound, "array.get at index"](index, self._size))

    @always_inline
    fn __getitem__(self, slice: Slice) -> Self:
        """Returns a new array that contains the values at the slice."""
        return Self(copy = self, size = slice.end - slice.start, start = slice.start, end = slice.end)

    @always_inline
    fn __setitem__(self, index: Int, value: T):
        """Sets the value at the provided index."""
        debug_assert(index >= 0 and index < self._size, "OUT OF BOUNDS (array.set at index)")
        self._data.store(BoundaryCondition.apply[bound, "array.set at index"](index, self._size), value)

    # TODO set at slice
    

    #------( Operations )------#
    #
    @always_inline
    fn __len__(self) -> Int:
        """Returns the size of this array."""
        return self._size

    @always_inline
    fn __bool__(self) -> Bool:
        """Returns true if this array has a size greater than zero."""
        return len(self) != 0

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Returns true if the arrays reference the same data."""
        return self._data == other._data

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Returns true if the arrays reference different data."""
        return self._data != other._data

    @always_inline
    fn deepcopy(self) -> Self:
        return Self(copy = self)

    @always_inline
    fn copy(self, other: Self, *, end: Int, start: Int = 0, offset: Int = 0):
        debug_assert(start <= end and start >= 0 and end <= other._size and self._size >= (end - start) + offset, "OUT OF BOUNDS (array.copy)")
        memcpy(self._data.offset(offset), other._data.offset(start), end - start)

    @always_inline
    fn append(self, *elements: T) -> Self:
        return Self(elements, copy = self)

    @always_inline
    fn remove(self, amount: Int) -> Self:
        debug_assert(amount <= self._size, "INVALID AMOUNT (array.remove)")
        var new_size = self._size - amount
        return Self(copy = self, size = new_size, end = new_size)

    fn shrink(self, size: Int) -> Self:
        debug_assert(size <= self._size, "INVALID SIZE (array.shrink)")
        return Self(copy = self, size = size, end = size)

    fn expand(self, size: Int) -> Self:
        debug_assert(size >= self._size, "INVALID SIZE (array.expand)")
        return Self(copy = self, size = size, end = self._size)

    @always_inline
    fn resize(self, size: Int) -> Self:
        debug_assert(size >= 0, "INVALID SIZE (array.expand)")
        return Self(copy = self, size = size, end = min(size, self._size))

    @always_inline
    fn clear(self):
        """Fills the entire array with zeros."""
        memset_zero(self._data, self._size)
    
    @always_inline
    fn clear(self, start: Int, end: Int):
        """Fills a range of the array with zeros."""
        debug_assert(start <= end and start >= 0 and end <= self._size, "OUT OF BOUNDS (array.clear)")
        memset_zero(self._data.offset(start), end - start)
    
    @always_inline
    fn fill(self, value: T):
        """Fills the entire array with a value."""
        for i in range(self._size): self[i] = value

    @always_inline
    fn fill(self, value: T, start: Int, end: Int):
        """Fills a range of the array with a value."""
        debug_assert(start <= end and start >= 0 and end <= self._size, "OUT OF BOUNDS (array.fill)")
        for i in range(start, end): self[i] = value
