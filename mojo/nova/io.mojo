from utils.index import StaticIntTuple as Ind
from .collections import *
from .graph.graph import Graph

fn say_the_thing(): print("hio world")

from utils.variant import Variant


#------ SmallVector[Int] to String ------#
#
fn str_(value: SmallVector[Int]) -> String:
    var result: String = ""
    var end: Int = len(value) - 1
    for i in range(end): result += str(value[i]) + "\n"
    return result + str(value[end])


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



fn eval_int_array(string: String) raises -> Array[Int]:
    """Evaluate the string as an array."""
    var cleaned: String = string
    cleaned = cleaned.replace("[", "")
    cleaned = cleaned.replace("]", "")
    cleaned = cleaned.replace("{", "")
    cleaned = cleaned.replace("}", "")

    if len(cleaned) == 0: raise Error("empty string")

    var splitted: List[String]

    try:
        splitted = cleaned.split(",")
        if len(splitted) == 1:
            splitted = cleaned.split("-")
    except:
        raise Error("empty delimiter")

    if len(splitted) == 0: raise Error("non parsable")

    var result: Array[Int] = Array[Int](size = len(splitted))

    try:
        for i in range(len(splitted)):
            result[i] = int(splitted[i])
    except:
        raise Error("non parsable")

    return result