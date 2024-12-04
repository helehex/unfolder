# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Layered Graph."""

from python import PythonObject


# +----------------------------------------------------------------------------------------------+ #
# | LGraph
# +----------------------------------------------------------------------------------------------+ #
#
@value
struct LGraph(Stringable, Value, Drawable):
    """Layered Edge Graph (multipartite graph). *This also contains meta data used in generation."""

    # +------[ Alias ]------+ #
    #
    alias NodeTable = Table[Int, (SpanBound.Unsafe, SpanBound.Unsafe), TableFormat(lbl="Nodes")]
    alias EdgeTable = Table[Ind2, (SpanBound.Unsafe, SpanBound.Unsafe), TableFormat(lbl="Edges")]

    # +------< Data >------+ #
    #
    var width: Int
    var depth: Int
    var node_count: Int
    var edge_count: Int
    var max_edge_out: Int
    var max_edge_weight: Int
    # var branch_count: Int

    var history: Array[Int]

    var nodes: Self.NodeTable
    var edges: Self.EdgeTable

    var weights: Array[Int, SpanBound.Unsafe]

    var _id2xy: Array[Ind2, SpanBound.Unsafe]
    var _id2lb: Array[Int, SpanBound.Unsafe]
    var _lb2id: Array[Int, SpanBound.Unsafe]

    # +------( Lifecycle )------+ #
    #
    fn __init__(out self):
        # --- initialize empty
        self.width = 0
        self.depth = 0
        self.node_count = 0
        self.edge_count = 0
        self.max_edge_out = 0
        self.max_edge_weight = 0
        self.history = Array[Int]()
        self.nodes = Self.NodeTable()
        self.edges = Self.EdgeTable()
        self.weights = Array[Int, SpanBound.Unsafe]()
        self._id2xy = Array[Ind2, SpanBound.Unsafe]()
        self._id2lb = Array[Int, SpanBound.Unsafe]()
        self._lb2id = Array[Int, SpanBound.Unsafe]()

    fn __init__(out self, width: Int, depth: Int, owned history: Array[Int]):
        var node_capacity = width * depth
        self.width = width
        self.depth = 0
        self.node_count = 0
        self.edge_count = 0
        self.max_edge_out = 0
        self.max_edge_weight = 0
        self.history = history
        self.nodes = Self.NodeTable(width, depth)
        self.edges = Self.EdgeTable(width, node_capacity)
        self.weights = Array[Int, SpanBound.Unsafe](size=node_capacity)
        self._id2xy = Array[Ind2, SpanBound.Unsafe](size=node_capacity)
        self._id2lb = Array[Int, SpanBound.Unsafe](size=node_capacity)
        self._lb2id = Array[Int, SpanBound.Unsafe](size=node_capacity + 1)

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

    fn ways(self) -> Int:
        return self.node_count

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

    fn write_to[
        WriterType: Writer
    ](self, mut writer: WriterType, str_nodes: Bool = True, str_edges: Bool = True):
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
        writer.write("id to xy: ", self._id2xy, "\n")
        writer.write("id to lb: ", self._id2lb, "\n")
        writer.write("lb to id: ", self._lb2id, "\n")

    fn write_relations_to[WriterType: Writer](self, mut writer: WriterType):
        """Format the graph as a set of relations: {1->2, 2->3, 3->0, ...}."""
        writer.write("{")
        var first = True
        for id_ in range(self.node_count):
            for _x in range(self.width):
                if self.edges[_x, id_][1] > 0:
                    if not first:
                        writer.write(", ")
                    else:
                        first = False
                    writer.write(
                        self.id2lb(id_), "<->", self.xy2lb(Ind2(_x, self.id2xy(id_)[1] + 1))
                    )
        writer.write("}")

    def draw(self, canvas: PythonObject):
        alias x_scale = 10
        alias y_scale = 50
        alias x_offset = 10
        alias y_offset = 10

        for node_id in range(self.node_count):
            var xy_ = self.id2xy(node_id)
            var _xy = Ind2(0, xy_[1] + 1)
            while self.next_neighbor(xy_, _xy):
                var color = "#00" + hex(
                    ((self.edges[_xy[0], node_id][1] * 200) // self.max_edge_weight) + 16, prefix=""
                ) + "00"
                canvas.create_line(
                    xy_[0] * x_scale + x_offset,
                    xy_[1] * y_scale + y_offset,
                    _xy[0] * x_scale + x_offset,
                    _xy[1] * y_scale + y_offset,
                    fill=color,
                )
                _xy[0] += 1

    # +------( Operations )------+ #
    #
    # color refinement isomorphism test
    fn color_heuristic(self) -> Freq[Int]:
        # TODO: This could be better,
        # should do color refinement on the disjoint union of two graphs
        # or at least check how many iterations it went through as well

        var node_colors = Array[Int](size=self.node_count)
        var new_node_colors = Array[Int](size=self.node_count)
        var color_map = Dict[Freq[Int], Int]()

        for id in range(self.node_count):
            var xy_ = self.id2xy(id)
            var _xy = Ind2(0, xy_[1] - 1)
            var edge_count = 0
            while self.next_neighbor(xy_, _xy):
                edge_count += 1
                _xy[0] += 1
            new_node_colors[id] = edge_count

        while node_colors != new_node_colors:
            node_colors = new_node_colors
            new_node_colors.clear()
            color_map.clear()
            for id in range(self.node_count):
                var xy_ = self.id2xy(id)
                var _xy = Ind2(0, xy_[1] - 1)
                var color_freq = Freq[Int]()
                while self.next_neighbor(xy_, _xy):
                    color_freq += node_colors[self.xy2id(_xy)]
                    _xy[0] += 1
                if color_freq not in color_map:
                    color_map[color_freq] = len(color_map)
                new_node_colors[id] = color_map.find(color_freq).unsafe_value()

        var result = Freq[Int]()
        for color in new_node_colors:
            result += color[]

        return result

    fn edge_heuristic(self) -> Freq[Int]:
        var result = Freq[Int]()
        for id in range(self.node_count):
            var xy_ = self.id2xy(id)
            var _xy = Ind2(0, xy_[1] - 1)
            var edge_count = 0
            while self.next_neighbor(xy_, _xy):
                edge_count += 1
                _xy[0] += 1
            result += edge_count
        return result

    fn __eq__(self, other: Self) -> Bool:
        # WIP
        if (
            self.node_count != other.node_count
            or self.edge_count != other.edge_count
            or self.max_edge_out != other.max_edge_out
        ):
            return False
        elif self.edge_heuristic() != other.edge_heuristic():
            return False
        elif self.color_heuristic() != other.color_heuristic():
            return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    fn touch(mut self, xy: Ind2):
        """Creates a new node entry at (x, y)."""
        if self.nodes[xy]:
            self.weights[self.xy2id(xy)] += 1
        else:
            self.unsafe_touch(xy)

    @always_inline
    fn unsafe_touch(mut self, xy: Ind2):
        """Assumes the node does not exist."""
        self._id2xy[self.node_count] = xy
        self.weights[self.node_count] += 1
        self.node_count += 1
        self.nodes[xy] = self.node_count
        self.depth = max(self.depth, xy[1] + 1)

    @always_inline
    fn reach(mut self, xy_: Ind2, _x: Int):
        var _xy = Ind2(_x, xy_[1] + 1)
        self.touch(_xy)
        var id_ = self.xy2id(xy_)
        var _id = self.xy2id(_xy)
        self.edges[_x, id_][1] += 1
        self.edges[xy_[0], _id][0] += 1

    @always_inline
    fn next_neighbor(self, xy_: Ind2, mut _xy: Ind2) -> Bool:
        if _xy[1] < xy_[1]:
            while _xy[0] < self.width:
                if self.edges[_xy[0], self.xy2id(xy_)][0] > 0:
                    return True
                _xy[0] += 1
            _xy = Ind2(0, xy_[1] + 1)

        while _xy[0] < self.width:
            if self.edges[_xy[0], self.xy2id(xy_)][1] > 0:
                return True
            _xy[0] += 1

        return False

    @always_inline
    fn finalize(mut self):
        """Finalize the generation of this graph."""
        self.shrink()
        self.finalize_edges()
        self.finalize_nodes()

    fn shrink(mut self):
        """Shrink data structures."""
        self.nodes.resize(self.width, self.depth)
        self.edges.resize(self.width, self.node_count)
        self.weights.resize(self.node_count)
        self._id2xy.resize(self.node_count)
        self._id2lb.resize(self.node_count)
        self._lb2id.resize(self.node_count + 1)

    fn finalize_edges(mut self):
        """Count edges."""
        for y in range(self.node_count):
            var edge_out = 0
            for x in range(self.width):
                var edge_weight = self.edges[x, y][1]
                if edge_weight:
                    self.max_edge_weight = max(self.max_edge_weight, edge_weight)
                    self.edge_count += 1
                    edge_out += 1
            self.max_edge_out = max(edge_out, self.max_edge_out)

    fn finalize_nodes(mut self):
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


# @value
# struct NeighborIter[mutability: Bool, //, origin: Origin[mutability].type, above: Bool, below: Bool]:
#     var graph: Reference[LayerGraph, origin]
#     var node: Int
#     var x: Int

#     fn __init__(out self, ref[origin] graph: LayerGraph, node: Int):
#         self.graph = graph
#         self.node = node
#         self.x = 0

#     fn __len__(self) -> Int:
#         return self.graph[].width - self.x

#     fn __next__(mut self) -> Int:
#         while self.graph[].edges[self.node, self.x][1] > 0:
#         var result = self.graph[].edges[]
#         self.x += 1
#         return result

# struct LayerGraphPermutation[mutability: Bool, //, origin: Origin[mutability].type]:
#     pass
