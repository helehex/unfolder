from sys import argv
from utils.index import StaticIntTuple as Ind
from array import Array, atol_array
from table import Table, Row
from graph import Graph
from hio import print_, str_
import rules

alias Ind2 = Ind[2]




# program entry point
fn main():

    var args = argv()
    var history = Array[Int](1)

    if len(args) > 1:
        try:
            history = atol_array(args[1])
        except e:
            history = Array[Int](1)
            print("error: ", e)

    print(rules.follow[rules.unfold](history))




#------ array test ------#
#
fn array_test():
    var array_none: Array[Int] = Array[Int]()
    var array_zero: Array[Int] = Array[Int](0)
    var array_empty: Array[Int] = Array[Int](10)
    var array_splat: Array[Int] = Array[Int](6,73)
    var row_ind: Array[Ind2] = Array[Ind2](6,Ind2(7,8))
    
    # append 1, then 2, to array_empty
    array_empty = Array[Int](array_empty,1)
    array_empty = Array[Int](array_empty,2)
    
    print("Array[Int]():\n" + str_(array_none), "\n")
    print("Array[Int](0):\n" + str_(array_zero), "\n")
    print("Array[Int](size=10), then append 1 and 2:\n" + str_(array_empty), "\n")
    print("Array[Int](size=6, splat=73):\n" + str_(array_splat), "\n")
    
    row_ind[3] = Ind2(1,2)
    print("Array[Ind2](size=6, splat=(7,8)), then set self[3] = (1,2):\n" + str_(row_ind), "\n")


#------ table test ------#
#
fn table_test():
    var table_none: Table[Int] = Table[Int]()
    var table_zero: Table[Int] = Table[Int](0,0)
    var table_cols: Table[Int] = Table[Int](6,0)
    var table_rows: Table[Int] = Table[Int](0,4)
    var table_empty: Table[Int] = Table[Int](5, 3)
    var table_splat: Table[Int] = Table[Int](2,2,5)

    print("Table[Int]():\n" + str_(table_none), "\n")
    print("Table[Int](0, 0):\n" + str_(table_zero), "\n")
    print("Table[Int](cols=6, 0):\n" + str_(table_cols), "\n")
    print("Table[Int](0, rows=4):\n" + str_(table_rows), "\n")
    print("Table[Int](cols=5, rows=3):\n" + str_(table_empty), "\n")
    print("Table[Int](cols=2, rows=2, splat=5):\n" + str_(table_splat), "\n")
    
    var table: Table[Int] = Table[Int](8,7,1) # create a new table, with 8 columns and 7 rows. populate with 1's
    Row(table, 2).splat(3)
    print("Create a new table, with 8 columns and 7 rows. populate with 1's, and splat a row of 3's:\n" + str_(table), "\n")
    
    var table2: Table[Int] = Table[Int](table) # copy entire table to new instance, table2
    table2[Ind2(5,5)] = 23
    table2[Ind2(2,5)] = 888 # set some values to table2
    table2[Ind2(3,1)] = 54
    Row(table2,6).splat(31) # creating Row(table, row), and splatting(31), will affect table2
    print("Table 2, copied from table 1, then some values set:\n" + str_(table2), "\n")
    
    var array: Array[Int] = table2.row(5).to_array()
    array[0] = 901
    array = Array[Int](12, array)
    print("Array from row 5 of table 2, index 0 was set, then the size was modified:\n" + str_(array), "\n")

    var row: Row[Int] = Row[Int](table2,5)
    row[0] = 301
    print("Row from row 5 of table 2, index 0 was set:\n" + str_(row), "\n")

    table2 = Table[Int](6,10,table2)
    Row(table2,table2._rows - 1).clear()
    table[Ind2(0,0)] += 55
    print("Modifying that row will affect table 2. I also changed the dimensions of table 1:\n" + str_(table2), "\n")
    print("table 1:\n" + str_(table), "\n")