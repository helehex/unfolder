from sys import argv
from nova.collections.array import *
from nova.io import *
import nova.rules


# program entry point
fn main():

    var args = argv()

    var history = Array[Int](1)
    var summary: Bool = False

    for i in range(1, len(args)):
        if args[i] == "-s": summary = True
        elif args[i][0] != "-":
            try:
                history = eval_int_array(args[i])
            except e:
                history = Array[Int](1)
                print("error: ", e)

    var result = rules.follow[rules.unfold](history)
    if summary: print(result.info_to_string())
    else: print(result)
    