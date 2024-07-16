from sys import argv
from src import *
import rules

def main():
    var args = argv()
    var history = Array[Int](1)
    var draw = True
    var print_nodes = False
    var print_edges = False
    var relation = False

    for i in range(1, len(args)):
        if args[i] == "-r":
            relation = True
        if args[i] == "-n":
            print_nodes = True
        if args[i] == "-e":
            print_edges = True
        if args[i] == "-d":
            draw = True
        elif args[i][0] != "-":
            try:
                history = Array[Int].eval["-"](args[i])
            except e:
                history = Array[Int](1)
                print("error: ", e)
    
    alias rule = rules.unfold_lg
    var result = rules.follow[rule](history)

    if relation:
        print(result.to_string_relations())
    else:
        print(result.to_string(print_nodes, print_edges))

    if draw:
        draw_graph(result, str(result.history))




from python import Python
from src.collections import LGraph

def draw_graph[T: Drawable](graph: T, title: String):
    var tk = Python.import_module("tkinter")
    var root = tk.Tk()
    var frame = tk.Frame(root)

    frame.master.title(title)
    frame.pack(fill=tk.BOTH, expand=1)

    var canvas = tk.Canvas(frame, bg="#000000")
    graph.draw(canvas)
    canvas.pack(fill=tk.BOTH, expand=1)

    # var py = Python()
    # _ = py.eval(p)
    root.geometry("1400x1400+300+300")
    root.mainloop()