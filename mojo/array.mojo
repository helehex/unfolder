from math import max, min
from memory.unsafe import Pointer
from memory import memset_zero, memcpy
from utils.index import StaticIntTuple as Ind




#------ Array ------#
#---
#--- simple heap allocated array
#---
struct Array[T: AnyRegType](Sized):
    var _size: Int
    var _rc: Pointer[Int]
    var _data: Pointer[T]
    
    @always_inline
    fn __init__(inout self):
        self._size = 0
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].get_null() # reference-only (no _data allocated)
        self._rc.store(0)
    
    @always_inline
    fn __init__(inout self, size: Int):
        self._size = size
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(size)
        self._rc.store(0)
        self.clear() # fills the entire array with 0's
        
    @always_inline
    fn __init__(inout self, size: Int, splat: T):
        self._size = size
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(size)
        self._rc.store(0)
        self.splat(splat) # fills the entire array with the value of splat
    
    @always_inline
    fn __init__(inout self, elements: VariadicList[T]):
        self._size = len(elements)
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(self._size)
        self._rc.store(0)
        for i in range(self._size): self[i] = elements[i]

    @always_inline
    fn __init__(inout self, owned array: Self): # owned array for the case of infinite self reference? (self = array)
        self._size = array._size
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(array._size) # uses the size from the array passed in
        self._rc.store(0)
        self.copy(array)
        
    @always_inline
    fn __init__(inout self, size: Int, owned array: Self):
        self._size = size
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(size) # uses the size defined localy
        self._rc.store(0)
        self.copy(array)
        self.clear(min(size, array._size), size)
        
    @always_inline
    fn __init__(inout self, owned array: Self, append: T):
        var size = array._size + 1
        self._size = size
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(size) # self.size = array.size + 1
        self._rc.store(0)
        self.copy(array)
        self[size - 1] = append # appends a value to the new array
    
    @always_inline
    fn __copyinit__(inout self, other: Self):
        (self._size, self._rc, self._data) = (other._size, other._rc, other._data)
        self._rc.store(self._rc.load() + 1)
    
    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        (self._size, self._rc, self._data) = (other._size, other._rc, other._data)
    
    @always_inline
    fn __del__(owned self):
        var rc = self._rc.load() - 1
        if rc < 0:
            self._rc.free()
            self._data.free()
            return
        self._rc.store(rc)
    
    @always_inline
    fn __len__(self) -> Int:
        return self._size

    @always_inline
    fn __getitem__(self, i: Int) -> T:
        #debug_assert(i < 0 or i >= self._size, "OUT OF BOUNDS (get i)")
        return self._data.load(i)

    @always_inline
    fn __setitem__(self, i: Int, o: T):
        #debug_assert(i < 0 or i >= self._size, "OUT OF BOUNDS (set i)")
        self._data.store(i, o)
    
    @always_inline
    fn copy(self, array: Self):
        var i: Int = min(self._size, array._size)
        #debug_assert(i < 0 or i > self._size, "OUT OF BOUNDS (copy array)")
        memcpy(self._data, array._data, i)
    
    @always_inline
    fn clear(self):
        memset_zero(self._data, self._size) # fill the entire array with zero's
    
    @always_inline
    fn clear(self, start: Int, end: Int):
        var count: Int = max(0, start - end)
        #debug_assert(count >= self._size, "OUT OF BOUNDS (clear range)")
        memset_zero(self._data.offset(start), count) # clears index >= i_, and < _i
    
    @always_inline
    fn splat(self, o: T):
        for i in range(self._size): self[i] = o


#------ Parse Int Array ------#
#
fn eval_array(s: String) raises -> Array[Int]:
    var cleaned: String = s
    cleaned = cleaned.replace("[", "")
    cleaned = cleaned.replace("]", "")
    cleaned = cleaned.replace("{", "")
    cleaned = cleaned.replace("}", "")

    if len(cleaned) == 0:
        raise Error("empty string")

    var splitted: DynamicVector[String]

    try:
        splitted = cleaned.split(",")
        if len(splitted) == 1:
            splitted = cleaned.split("-")
    except:
        raise Error("empty delimiter")

    if len(splitted) == 0:
        raise Error("non parsable")

    var result: Array[Int] = Array[Int](len(splitted))

    try:
        for i in range(len(splitted)):
            result[i] = atol(splitted[i])
    except:
        raise Error("non parsable")

    return result