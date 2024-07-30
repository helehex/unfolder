# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #

from testing import *
from nova.testing import *

from sys.intrinsics import _type_is_eq
from nova import Table


def main():
    test_subscript()
    test_truthy()
    test_equality()


def test_subscript():
    var tbl = Table[Int](cols=5, rows=6)
    assert_equal(tbl[0, 0], 0)
    tbl[0, 0] = 3
    assert_equal(tbl[0, 0], 3)
    assert_equal(tbl[5, 4], 0)
    tbl[5, 4] = 4
    assert_equal(tbl[5, 4], 4)


def test_truthy():
    assert_false(Table[Int]())
    assert_false(Table[Int](cols=1, rows=0))
    assert_false(Table[Int](cols=0, rows=1))
    assert_true(Table[Int](cols=1, rows=1))


def test_equality():
    assert_equal(Table[Int](), Table[Int]())
    assert_equal(Table[Int](), Table[Int](cols=0, rows=0))
    assert_equal(Table[Int](cols=1, rows=0), Table[Int](cols=1, rows=0))
    assert_equal(Table[Int](cols=0, rows=1), Table[Int](cols=0, rows=1))
    assert_equal(Table[Int](cols=1, rows=1), Table[Int](cols=1, rows=1))


# ------ table test ------#
#
# fn table_test():
#     pass
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
