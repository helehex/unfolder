from utils.index import StaticIntTuple as Ind
from array import Array
from table import Table, Row, reduce_max
from graph import Graph

fn say_the_thing(): print("hio world")

from utils.variant import Variant


# #------ Array[Stringable] to String
# #
# fn str_[T: Stringable](o: Array[T]) -> String:
#     var s: String = "["
#     for x in range(o._size - 1): s += String(o[x]) + ", "
#     if o._size > 0: s += String(o[o._size - 1])
#     s += "]"
#     return s
# fn print_[T: AnyType](o: Array[T]): print(str_(o))


#------ Array[Int] to String
#
fn str_(o: Array[Int]) -> String:
    var s: String = "["
    for x in range(o._size - 1): s += String(o[x]) + ", "
    if o._size > 0: s += String(o[o._size - 1])
    s += "]"
    return s
fn print_(o: Array[Int]): print(str_(o))


#------ Array[Ind2] to String
#
fn str_(o: Array[Ind[2]]) -> String:
    var s: String = "["
    for x in range(o._size - 1): s += String(o[x]) + ", "
    if o._size > 0: s += String(o[o._size - 1])
    s += "]"
    return s
fn print_(o: Array[Ind[2]]): print(str_(o))


#------ Table[Int] to String
#
# pad aligns each column
#
fn str_(o: Table[Int]) -> String:
    var room = len(String(reduce_max(o)))
    var s: String = ""
    for y in range(o._rows - 1): s += str_(Row(o,y), room) + "\n"
    if o._rows > 0: s += str_(Row(o, o._rows - 1), room)
    else: return "-"
    return s
fn print_(o: Table[Int]): print(str_(o))


#------ Row[Int] to String
#
# pad aligns each column
#
fn str_(o: Row[Int], pad: Int) -> String:
    var s: String = "{"
    var lm: Int = o._cols - 1
    @parameter
    fn _pad(i: Int):
        for rm in range(pad - len(String(o[i]))): s += " "
    for x in range(lm):
        _pad(x)
        s += String(o[x]) + ", "
    if o._cols > 0:
        _pad(lm)
        s += String(o[lm])
    s += "}"
    return s
fn str_(o: Row[Int]) -> String: return str_(o, len(String(reduce_max(o))))
fn print_(o: Row[Int]): print(str_(o))