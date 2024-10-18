# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Adjacency Matrix Graph."""

from python import PythonObject


# +----------------------------------------------------------------------------------------------+ #
# | MGraph
# +----------------------------------------------------------------------------------------------+ #
#
@value
struct MGraph(Stringable, Value, Drawable):
    """Adjacency Matrix Graph. *This also contains meta data used in generation."""

    # +------[ Alias ]------+ #
    #
    alias NodeTable = Table[Int, (SpanBound.Unsafe, SpanBound.Unsafe), TableFormat(lbl="Nodes")]
    alias EdgeTable = Table[Int, (SpanBound.Unsafe, SpanBound.Unsafe), TableFormat(lbl="Edges")]

    # +------< Data >------+ #
    #
    var history: Array[Int]
    """The graphs history of origin selection."""

    var nodes: Self.NodeTable
    """The graphs node table."""
    var edges: Self.EdgeTable
    """The graphs edge table."""

    var width: Int
    var depth: Int
    var node_count: Int
    var edge_count: Int
    var max_edge_out: Int
    var max_edge_weight: Int

    var weights: Array[Int]
    """Node weights. Touching a node will increment it's weight."""
    var bounds: Array[Ind2]
    """Edge bounds for optimizing neighbor traversal."""

    var _id2xy: Array[Ind2]
    """converts a node ID to it's (x, y) coordinates."""
    var _id2lb: Array[Int]
    """converts a node ID to it's retroactive label."""
    var _lb2id: Array[Int]
    """converts a nodes label to it's original ID."""

    # +------( Lifecycle )------+ #
    #
    fn __init__(inout self):
        self.width = 0
        self.depth = 0
        self.node_count = 0
        self.edge_count = 0
        self.max_edge_out = 0
        self.max_edge_weight = 0
        self.history = Array[Int]()
        self.nodes = Self.NodeTable()
        self.edges = Self.EdgeTable()
        self.weights = Array[Int]()
        self.bounds = Array[Ind2]()
        self._id2xy = Array[Ind2]()
        self._id2lb = Array[Int]()
        self._lb2id = Array[Int]()

    fn __init__(inout self, width: Int, depth: Int, owned history: Array[Int]):
        var node_capacity = width * depth
        self.width = width
        self.depth = depth
        self.node_count = 0
        self.edge_count = 0
        self.max_edge_out = 0
        self.max_edge_weight = 0
        self.history = history
        self.nodes = Self.NodeTable(width, depth)
        self.edges = Self.EdgeTable(node_capacity, node_capacity)
        self.weights = Array[Int](size=node_capacity)
        self.bounds = Array[Ind2](size=node_capacity)
        self._id2xy = Array[Ind2](size=node_capacity)
        self._id2lb = Array[Int](size=node_capacity)
        self._lb2id = Array[Int](size=node_capacity + 1)

    # +------( Lookups )------+ #
    #
    @always_inline
    fn xy2id(self, xy: Ind2) -> Int:
        return self.nodes[xy] - 1

    @always_inline
    fn xy2lb(self, xy: Ind2) -> Int:
        return self._id2lb[self.xy2id(xy)]

    @always_inline
    fn lb2id(self, lb: Int) -> Int:
        return self._lb2id[lb]

    @always_inline
    fn lb2xy(self, lb: Int) -> Ind2:
        return self._id2xy[self.lb2id(lb)]

    @always_inline
    fn id2xy(self, id: Int) -> Ind2:
        return self._id2xy[id]

    @always_inline
    fn id2lb(self, id: Int) -> Int:
        return self._id2lb[id]

    # +------( Format )------+ #
    #
    fn __str__(self) -> String:
        return self.to_string()

    fn to_string(self, str_nodes: Bool = True, str_edges: Bool = True) -> String:
        var result: String = ""
        self.write_to(result, str_nodes, str_edges)
        return result

    fn to_string_relations(self) -> String:
        var result: String = ""
        self.write_relations_to(result)
        return result

    fn write_to[WriterType: Writer](self, inout writer: WriterType, str_nodes: Bool = True, str_edges: Bool = True):
        """Format the graph."""
        writer.write("history: ", self.history, "\n")
        writer.write("width: ", self.width, "\n")
        writer.write("depth: ", self.depth, "\n\n")
        writer.write("nodes: (count: ", self.node_count, ")\n")
        if str_nodes:
            writer.write(self.nodes, "\n")
        writer.write("weights: ", self.weights, "\n\n")
        writer.write("edges: (count: ", self.edge_count, ", max_out: ", self.max_edge_out, ")\n")
        if str_edges:
            writer.write(self.edges, "\n")
        writer.write("bounds: ", self.bounds, "\n\n")
        writer.write("id to xy: ", self._id2xy, "\n")
        writer.write("id to lb: ", self._id2lb, "\n")
        writer.write("lb to id: ", self._lb2id, "\n")

    fn write_relations_to[WriterType: Writer](self, inout writer: WriterType):
        """Format the graph as a set of relations: {1->2, 2->3, 3->0, ...}."""
        writer.write("{")
        var first = True
        for y in range(self.node_count):
            var start = self.bounds[y][0]
            var stop = self.bounds[y][1]
            if start < y:
                start = y
            for x in range(start, stop):
                if self.edges[x, y] > 0:
                    if not first:
                        writer.write(", ")
                    else:
                        first = False
                    writer.write(self.id2lb(y), "->", self.id2lb(x))
        writer.write("}")

    def draw(self, canvas: PythonObject):
        alias x_scale = 10
        alias y_scale = 50
        alias x_offset = 10
        alias y_offset = 10

        for id_ in range(self.node_count):
            var xy_ = self.id2xy(id_)
            var _id = self.bounds[id_][0]
            while self.next_neighbor(id_, _id):
                var _xy = self.id2xy(_id)
                var color = "#00" + hex(
                    ((self.edges[_id, id_] * 200) // self.max_edge_weight) + 16, prefix=""
                ) + "00"
                canvas.create_line(
                    xy_[0] * x_scale + x_offset,
                    xy_[1] * y_scale + y_offset,
                    _xy[0] * x_scale + x_offset,
                    _xy[1] * y_scale + y_offset,
                    fill=color,
                )
                _id += 1

    # +------( Operations )------+ #
    #
    fn __eq__(self, other: Self) -> Bool:
        # WIP
        if (
            self.node_count != other.node_count
            or self.edge_count != other.edge_count
            or self.max_edge_out != other.max_edge_out
        ):
            return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    fn touch(inout self, xy: Ind2):
        """Creates a new node entry at (x, y)."""
        if self.nodes[xy]:
            self.weights[self.xy2id(xy)] += 1
        else:
            self.unsafe_touch(xy)

    @always_inline
    fn unsafe_touch(inout self, xy: Ind2):
        """Assumes the node does not exist."""
        self._id2xy[self.node_count] = xy
        self.weights[self.node_count] += 1
        self.node_count += 1
        self.nodes[xy] = self.node_count

    @always_inline
    fn reach(inout self, src: Int, dst: Int, depth: Int):
        """Creates an edge from the src node to the dst node. Touches the dst node if it has not been touched yet.
        """
        var src_xy = Ind2(src, depth - 1)
        var dst_xy = Ind2(dst, depth)
        if self.nodes[dst_xy] == 0:
            self._id2xy[self.node_count] = dst_xy
            self.node_count += 1
            self.nodes[dst_xy] = self.node_count
        var i_: Int = self.nodes[src_xy] - 1
        var _i: Int = self.nodes[dst_xy] - 1
        self.weights[_i] += 1
        self.edges[Ind2(_i, i_)] += 1
        self.edges[Ind2(i_, _i)] += 1

    @always_inline
    fn next_neighbor(self, id_: Int, inout _id: Int) -> Bool:
        while _id < self.bounds[id_][1]:
            if self.edges[_id, id_]:
                return True
            _id += 1
        return False

    @always_inline
    fn finalize(inout self):
        """Finalize the generation of this graph."""
        self.shrink()
        self.finalize_edges()
        self.finalize_nodes()

    fn shrink(inout self):
        """Shrink data structures."""
        self.nodes.resize(self.width, self.depth)
        self.edges.resize(self.node_count, self.node_count)
        self.weights.resize(self.node_count)
        self.bounds.resize(self.node_count)
        self._id2xy.resize(self.node_count)
        self._id2lb.resize(self.node_count)
        self._lb2id.resize(self.node_count + 1)

    fn finalize_edges(inout self):
        """Find the first and last edge for each nodes edge row, and count edges."""
        for y in range(self.node_count):
            var row = self.edges.row(y)
            var start = self.node_count
            var limit = 0
            var edge_out = 0
            for x in range(self.node_count):
                var edge_weight = row[x]
                if edge_weight:
                    self.max_edge_weight = max(self.max_edge_weight, edge_weight)
                    self.edge_count += 1
                    edge_out += 1
                    start = min(x, start)
                    limit = max(x, limit)
            self.max_edge_out = max(edge_out, self.max_edge_out)
            self.bounds[y] = Ind2(start, limit + 1)

    fn finalize_nodes(inout self):
        """Label nodes chronologically. Some rules can confuses the node labeling. This helps keep history consitent.
        """
        var l = 0
        for y in range(self.depth):
            for x in range(self.width):
                var i = self.nodes[x, y]
                if i > 0:
                    i -= 1
                    l += 1
                    self._lb2id[l] = i
                    self._id2lb[i] = l
                    # self.nodes[x, y] = l
