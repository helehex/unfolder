from collections import Set


@value
struct Edge:
    var src: Int
    var dst: Int

    fn __hash__(self) -> UInt:
        return self.src.__hash__() - self.dst.__hash__()

    fn __eq__(self, other: Self) -> Bool:
        return self.src == other.src and self.dst == other.dst

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


struct Graph:
    var nodes: Dict[Int, Ind2]
    var edges: Set[Edge]

    fn __init__(out self):
        self.nodes = Dict[Int, Ind2]()
        self.edges = Set[Edge]()

    fn __moveinit__(inout self, owned other: Self):
        self.nodes = other.nodes^
        self.edges = other.edges^

    fn reach(inout self, src: Int, dst: Int, dst_xy: Ind2):
        self.nodes[dst] = dst_xy
        self.edges.add(Edge(src, dst))

    def draw(self, canvas: PythonObject):
        alias x_scale = 10
        alias y_scale = 200
        alias x_offset = 10
        alias y_offset = 10

        for edge in self.edges:
            var xy_ = self.nodes[edge[].src]
            var _xy = self.nodes[edge[].dst]
            var color = "#00FFFF"
            canvas.create_line(
                xy_[0] * x_scale + x_offset,
                xy_[1] * y_scale + y_offset,
                _xy[0] * x_scale + x_offset,
                _xy[1] * y_scale + y_offset,
                fill=color,
            )
