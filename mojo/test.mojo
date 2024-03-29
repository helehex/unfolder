from nova.collections import *
from nova.graph import *
from nova.io import *

from collections.vector import InlinedFixedVector

fn main():
    array_test()
    print()
    small_vector_test()

#------ Array Test ------#
#
fn array_test():
    var a: Array[Int]

    # initialize
    a = Array[Int]()
    print("new ----------", str_(a), True if a else False)
    a = Array[Int](size = 5)
    print("new ----------", str_(a), True if a else False)
    a = Array[Int](size = 5, fill = 1)
    print("new ----------", str_(a))
    a = VariadicList[Int](1,2,3,4,5)
    print("new ----------", str_(a))
    a = Array[Int](1,2,3,4,5)
    print("new ----------", str_(a))
    a = Array[Int](copy = Array[Int](1,2,3,4,5), size = 6, end = 5)
    print("new ----------", str_(a))
    a = Array[Int](copy = Array[Int](0,1,2,3,4,5,6), size = 5, start = 2, end = 7)
    print("new ----------", str_(a))
    a = Array[Int](copy = a)
    print("new ----------", str_(a))

    print("--------- rc:", a._get_rc())

    # get / set
    a[1] = -2
    print("get index ----", a[1])
    print("get slice ----", str_(a[1:4]))
    
    # rc
    var b = a
    print("--------- rc:", a._get_rc())

    # expand / shrink
    print("shrink 2 -----", str_(b.shrink(2)))
    print("expand 8 -----", str_(a.expand(8)))

    # append / remove
    print("append 6, 7 --", str_(b.append(6,7)))
    print("remove 2 -----", str_(a.remove(2)))

    #rc
    var c = b.deepcopy()
    print("deepcopy -----", str_(c))
    print("--------- rc:", a._get_rc())
    print("--------- rc:", b._get_rc())


#------ Small Vector Test ------#
#
fn small_vector_test():
    var a = SmallVector[Int, 8, BoundaryCondition.Overlap](0, 1, 2)
    var b = SmallVector[Int, 8, BoundaryCondition.Overlap](0, 1, 2)
    a.append(3)
    print(a)
    print()
    print(a.pop())
    print(a == b)
    print(a[-2])
    print()
    print(a)


#------ table test ------#
#
fn table_test():
    pass
    # var table_none: Table[Int] = Table[Int]()
    # var table_zero: Table[Int] = Table[Int](0,0)
    # var table_cols: Table[Int] = Table[Int](6,0)
    # var table_rows: Table[Int] = Table[Int](0,4)
    # var table_empty: Table[Int] = Table[Int](5, 3)
    # var table_splat: Table[Int] = Table[Int](2,2,5)

    # print("Table[Int]():\n" + str_(table_none), "\n")
    # print("Table[Int](0, 0):\n" + str_(table_zero), "\n")
    # print("Table[Int](cols=6, 0):\n" + str_(table_cols), "\n")
    # print("Table[Int](0, rows=4):\n" + str_(table_rows), "\n")
    # print("Table[Int](cols=5, rows=3):\n" + str_(table_empty), "\n")
    # print("Table[Int](cols=2, rows=2, splat=5):\n" + str_(table_splat), "\n")
    
    # var table: Table[Int] = Table[Int](8,7,1) # create a new table, with 8 columns and 7 rows. populate with 1's
    # Row(table, 2).splat(3)
    # print("Create a new table, with 8 columns and 7 rows. populate with 1's, and splat a row of 3's:\n" + str_(table), "\n")
    
    # var table2: Table[Int] = Table[Int](table) # copy entire table to new instance, table2
    # table2[Ind2(5,5)] = 23
    # table2[Ind2(2,5)] = 888 # set some values to table2
    # table2[Ind2(3,1)] = 54
    # Row(table2,6).splat(31) # creating Row(table, row), and splatting(31), will affect table2
    # print("Table 2, copied from table 1, then some values set:\n" + str_(table2), "\n")
    
    # var array: Array[Int] = table2.row(5).to_array()
    # array[0] = 901
    # array = Array[Int](12, array)
    # print("Array from row 5 of table 2, index 0 was set, then the size was modified:\n" + str_(array), "\n")

    # var row: Row[Int] = Row[Int](table2,5)
    # row[0] = 301
    # print("Row from row 5 of table 2, index 0 was set:\n" + str_(row), "\n")

    # table2 = Table[Int](6,10,table2)
    # Row(table2,table2._rows - 1).clear()
    # table[Ind2(0,0)] += 55
    # print("Modifying that row will affect table 2. I also changed the dimensions of table 1:\n" + str_(table2), "\n")
    # print("table 1:\n" + str_(table), "\n")