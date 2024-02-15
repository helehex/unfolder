from math import max, min
from math.limit import min_finite
from memory.unsafe import Pointer
from memory import memset_zero, memcpy
from utils.index import StaticIntTuple as Ind
from array import Array




#------ Table ------#
    
struct Table[T: AnyRegType]:
    var _size: Int
    var _cols: Int
    var _rows: Int
    var _rc: Pointer[Int]
    var _data: Pointer[T]
    
    @always_inline
    fn __init__(inout self):
        (self._size, self._cols, self._rows) = (0,0,0)
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].get_null()
        self._rc.store(0)
    
    @always_inline
    fn __init__(inout self, cols: Int, rows: Int):
        let size = cols*rows
        (self._size, self._cols, self._rows) = (size, cols, rows)
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(size)
        self._rc.store(0)
        self.clear()
        
    @always_inline
    fn __init__(inout self, cols: Int, rows: Int, splat: T):
        let size = cols*rows
        (self._size, self._cols, self._rows) = (size, cols, rows)
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(size)
        self._rc.store(0)
        self.splat(splat)
        
    @always_inline
    fn __init__(inout self, owned table: Table[T]):
        (self._size, self._cols, self._rows) = (table._size, table._cols, table._rows)
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(table._size)
        self._rc.store(0)
        self.copy(table)
    
    @always_inline
    fn __init__(inout self, cols: Int, rows: Int, owned table: Table[T]):
        let size = cols*rows
        (self._size, self._cols, self._rows) = (size, cols, rows)
        self._rc = Pointer[Int].alloc(1)
        self._data = Pointer[T].alloc(size)
        self._rc.store(0)
        self.copy(table)
        self.clear(Ind[2](min(cols, table._cols), min(rows, table._rows)), Ind[2](cols, rows))
        _ = table
    
    @always_inline
    fn __copyinit__(inout self, other: Self):
        (self._size, self._cols, self._rows) = (other._size, other._cols, other._rows)
        self._rc = other._rc
        self._data = other._data
        self._rc.store(self._rc.load() + 1)
    
    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        (self._size, self._cols, self._rows) = (other._size, other._cols, other._rows)
        self._rc = other._rc
        self._data = other._data
    
    @always_inline
    fn __del__(owned self):
        let rc = self._rc.load() - 1
        if rc < 0:
            self._rc.free()
            self._data.free()
            return
        self._rc.store(rc)
    
    @always_inline
    fn __getitem__(self, i: Int) -> T:
        #debug_assert(i < 0 or i >= self._size, "OUT OF BOUNDS (get i)")
        return self._data.load(i)
    
    @always_inline
    fn __getitem__(self, index: Ind[2]) -> T:
        let i: Int = self.int_ind(index)
        #debug_assert(i < 0 or i >= self._size, "OUT OF BOUNDS (get index table)")
        return self._data.load(i)

    @always_inline
    fn __setitem__(self, index: Ind[2], o: T):
        let i: Int = self.int_ind(index)
        #debug_assert(i < 0 or i >= self._size, "OUT OF BOUNDS (set index)")
        self._data.store(i, o)
    
    @always_inline
    fn int_ind(self, index: Ind[2]) -> Int:
        return index[0] + index[1]*self._cols
    
    @always_inline
    fn copy(self, table: Self):
        if self._cols == table._cols and self._rows == table._rows:
            memcpy(self._data, table._data, self._size)
        else:
            let rows = min(self._rows, table._rows)
            for y in range(rows):
                #debug_assert(y < 0 or y >= self._rows, "OUT OF BOUNDS (copy rows y)")
                Row(self, y).copy(Row(table, y))
    
    @always_inline
    fn clear(self):
        memset_zero(self._data, self._size)
        
    @always_inline
    fn clear(self, o_: Ind[2], _o: Ind[2]):
        for y in range(o_[1]):
            #debug_assert(y < 0 or y >= self._rows, "OUT OF BOUNDS (clear range y partial x)")
            Row(self, y).clear(o_[0], _o[0])
        for y in range(o_[1],_o[1]):
            #debug_assert(y < 0 or y >= self._rows, "OUT OF BOUNDS (clear range y full x) ")
            Row(self, y).clear()
    
    @always_inline
    fn splat(self, o: T):
        for y in range(self._rows): Row(self, y).splat(o)      
        
    @always_inline
    fn row(self, y: Int) -> Row[T]:
        return Row[T](self,y)
        
#------ Row ------#
        
struct Row[T: AnyRegType]:
    var _cols: Int
    var _data: Pointer[T]
    
    @always_inline
    fn __init__(inout self, table: Table[T], row: Int):
        self._cols = table._cols
        self._data = table._data.offset(row*table._cols)
        
    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        self._cols = other._cols
        self._data = other._data
        
    @always_inline
    fn __getitem__(self, x: Int) -> T:
        #debug_assert(x < 0 or x >= self._table._size, "OUT OF BOUNDS (get i)")
        return self._data.load(x)

    @always_inline
    fn __setitem__(self, x: Int, o: T):
        #debug_assert(x < 0 or x >= self._table._size, "OUT OF BOUNDS (set i)")
        self._data.store(x, o)
    
    @always_inline
    fn copy(self, row: Self):
        let x: Int = min(self._cols, row._cols)
        #debug_assert(x < 0 or x > self._table._cols, "OUT OF BOUNDS (copy row x)")
        memcpy(self._data, row._data, x)
    
    @always_inline
    fn clear(self):
        memset_zero(self._data, self._cols)
    
    @always_inline
    fn clear(self, o_: Int, _o: Int):
        let c: Int = max(0, _o - o_)
        #debug_assert(c < 0 or c > self._table._cols, "OUT OF BOUNDS (clear row, !count)")
        #debug_assert(o_ < 0 or o_ > self._table._cols, "OUT OF BOUNDS (clear row, !o_)")
        memset_zero(self._data.offset(o_), c) # clears index >= o_, and < _o
    
    @always_inline
    fn splat(self, o: T):
        for i in range(self._cols): self[i] = o

    @always_inline
    fn to_array(self) -> Array[T]:
        var array: Array[T] = Array[T]()
        array._size = self._cols
        array._data = Pointer[T].alloc(self._cols)
        let i: Int = min(array._size, self._cols)
        memcpy(array._data, self._data, i)
        return array




# return the highest <Int> in a table of <Int>
fn reduce_max(o: Table[Int]) -> Int:
    var m: Int = min_finite[DType.int64]().__int__()
    for i in range(o._size): m = max(o[i], m)
    return m

# return the highest <Int> in a row of <Int>
fn reduce_max(o: Row[Int]) -> Int:
    var m: Int = min_finite[DType.int64]().__int__()
    for i in range(o._cols): m = max(o[i], m)
    return m