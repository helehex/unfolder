from math import min, max
from utils.index import StaticIntTuple as Ind
from array import Array
from table import Table, Row
from hio import str_

alias Ind2 = Ind[2]




#------------ node-edge Graph
#---
#------ uses a sparse optimized edge matrix/table
#------ the unfolder uses the bounds property to sparse optimize the crawl
#------ edge table's memory layout is not currently optimized sparsely
#------ mostly just a container (without much interface currently) which the unfolder uses
#---
struct Graph(Stringable):

    #------< Data >------#
    #
    var width: Int
    var depth: Int
    var node_count: Int
    var edge_count: Int
    var max_edge_out: Int
    
    var history: Array[Int]   # history of origin selection
    
    var nodes: Table[Int]     # x = space, y = time     Int ~ unsorted id     accessed by [previous_node_index, depth]     0 = no node, {node_index + 1} = node
    var edges: Table[Int]     # x = edges, y = nodes    Int ~ weight          accessed by [node_index, node_index]         0 = no edge, {weight} = edge
    
    var weights: Array[Int]   # the nodes weights, can represent the self loop
    var bounds: Array[Ind2]   # Ind2[0] = edge_start, Ind2[1] = edge_end
    
    var _xy_id: Array[Ind2]   # to_point[unsorted id] = table coordinates
    var _lb_id: Array[Int]    # to_label[unsorted id] = sorted id
    var _id_lb: Array[Int]    # to_index[sorted id] = unsorted id


    #------ lifetime ------#
    #
    fn __init__(inout self):
        #--- initialize empty
        self.width = 0
        self.depth = 0
        self.node_count = 0
        self.edge_count = 0
        self.max_edge_out = 0
        self.history = Array[Int]()
        self.nodes = Table[Int]()
        self.edges = Table[Int]()
        self.weights = Array[Int]()
        self.bounds = Array[Ind2]()
        self._xy_id = Array[Ind2]()
        self._lb_id = Array[Int]()
        self._id_lb = Array[Int]()
    
    fn __init__(inout self, 
    owned history: Array[Int], 
    owned nodes: Table[Int], 
    owned edges: Table[Int], 
    owned weights: Array[Int], 
    owned _xy_id: Array[Ind2]):
    
        #--- initialize with node and edge data, then compute bounds and labels
        
        # set knowns
        self.width = nodes._cols
        self.depth = nodes._rows
        self.node_count = edges._cols
        self.edge_count = 0
        self.max_edge_out = 0
        self.history = history
        self.nodes = nodes
        self.edges = edges
        self.bounds = Array[Ind2](self.node_count)
        self.weights = weights
        self._xy_id = _xy_id
        self._lb_id = Array[Int](self.node_count)
        self._id_lb = Array[Int](self.node_count + 1)

        # find edge_start and edge_limit for each nodes edge row, and count edges
        for y in range(self.node_count):
            var row = Row(self.edges,y)
            var start: Int = self.node_count
            var limit: Int = 0
            var edge_out: Int = 0
            for x in range(self.node_count):
                if row[x] > 0:
                    self.edge_count += 1
                    edge_out += 1
                    start = min(x, start)
                    limit = max(x, limit)
            self.max_edge_out = max(edge_out, self.max_edge_out)
            self.bounds[y] = Ind2(start, limit + 1)

        # label nodes chronologically. the main proccess usually confuses the node labeling, so this helps keep history consitent
        var l: Int = 0
        for y in range(self.depth):
            for x in range(self.width):
                var i: Int = self.nodes[Ind2(x,y)] # the tables entry at x,y
                if i > 0:
                    i -= 1
                    l += 1
                    self._id_lb[l] = i
                    self._lb_id[i] = l

    fn __moveinit__(inout self, owned other: Self):
        self.width = other.width
        self.depth = other.depth
        self.node_count = other.node_count
        self.edge_count = other.edge_count
        self.max_edge_out = other.max_edge_out
        self.history = other.history
        self.nodes = other.nodes
        self.edges = other.edges
        self.weights = other.weights
        self.bounds = other.bounds
        self._xy_id = other._xy_id
        self._lb_id = other._lb_id
        self._id_lb = other._id_lb


    #------ lookups ------#
    #
    @always_inline
    fn id_xy(self, xy: Ind2) -> Int: return self.nodes[xy].__int__() - 1   # node-coordinates to node-id
    @always_inline
    fn lb_xy(self, xy: Ind2) -> Int: return self._lb_id[self.id_xy(xy)]    # node-coordinates to node-label
    @always_inline
    fn id_lb(self, lb: Int) -> Int: return self._id_lb[lb]                 # node-label to node-id
    @always_inline
    fn xy_lb(self, lb: Int) -> Ind2: return self._xy_id[self.id_lb(lb)]    # node-label to node-coordinates
    @always_inline
    fn xy_id(self, id: Int) -> Ind2: return self._xy_id[id]                # node-id to node-coordinates
    @always_inline
    fn lb_id(self, id: Int) -> Int: return self._lb_id[id]                 # node-id to node_label


    #------( Format )------#
    #
    fn __str__(self) -> String:
        return self.to_string()

    #------ Graph to String
    #
    fn to_string(self) -> String:
        var s: String = ""
        s += "history: " + str_(self.history) + "\n"
        s += "width: " + str(self.width) + "\n"
        s += "depth: " + str(self.depth) + "\n\n"
        s += "nodes: (count: " + str(self.node_count) + ")\n" + str_(self.nodes) + "\n"
        s += "weights: " + str_(self.weights) + "\n\n"
        s += "edges: (count: " + str(self.edge_count) + ", max_out: " + str(self.max_edge_out) + ")\n" + str_(self.edges) + "\n"
        s += "bounds: " + str_(self.bounds) + "\n\n"
        s += "id to xy: " + str_(self._xy_id) + "\n" # not infering parameter? is this expected?
        s += "id to lb: " + str_(self._lb_id) + "\n"
        s += "lb to id: " + str_(self._id_lb) + "\n"
        return s

    #------ Graph info to String
    #
    fn info_to_string(self) -> String:
        var s: String = ""
        s += "history: " + str_(self.history) + "\n"
        s += "width: " + str(self.width) + "\n"
        s += "depth: " + str(self.depth) + "\n\n"
        s += "nodes: (count: " + str(self.node_count) + ")\n"
        s += "weights: " + str_(self.weights) + "\n\n"
        s += "edges: (count: " + str(self.edge_count) + ", max_out: " + str(self.max_edge_out) + ")\n"
        return s

    #------ Graph (relations) to String
    #
    fn relations_to_string(self) -> String: #--- returns a string formatted as a set of relations: {1->2, 2->3, 3->0,...}
        var s: String = "{"
        for y in range(self.node_count):
            var start: Int = self.bounds[y][0]
            var limit: Int = self.bounds[y][1]
            if start < y: start = y
            for x in range(start, limit):
                if self.edges[Ind[2](x,y)] > 0:
                    if len(s) != 1: s += ", "
                    s += String(self.lb_id(y))+"->"+String(self.lb_id(x))
        return s + "}"