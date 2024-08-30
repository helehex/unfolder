# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Contains rules, and the means to follow them.

Example: `follow[unfold]()`
"""

from src import *


# +----------------------------------------------------------------------------------------------+ #
# | Follow
# +----------------------------------------------------------------------------------------------+ #
#
fn follow[rule: fn (MGraph, Int) -> MGraph](owned *history: Int) -> MGraph:
    """Follow a `rule` with respect to an origin `history`, and return the resulting graph."""
    return follow[rule](history)


fn follow[rule: fn (MGraph, Int) -> MGraph](history: Array[Int]) -> MGraph:
    """Follow a `rule` with respect to an origin `history`, and return the resulting graph."""
    var result = MGraph()
    for i in range(len(history)):
        result = rule(result, history[i])
    return result^


fn follow[rule: fn (LGraph, Int) -> LGraph](owned *history: Int) -> LGraph:
    """Follow a `rule` with respect to an origin `history`, and return the resulting graph."""
    return follow[rule](history)


fn follow[rule: fn (LGraph, Int) -> LGraph](history: Array[Int]) -> LGraph:
    """Follow a `rule` with respect to an origin `history`, and return the resulting graph."""
    var result = LGraph()
    for i in range(len(history)):
        result = rule(result, history[i])
    return result^


# +----------------------------------------------------------------------------------------------+ #
# | Unfolder Matrix Graph
# +----------------------------------------------------------------------------------------------+ #
#
# +--- nodes are considered self-edges
# +---
# +--- Starting at node `N` in graph `G`, and using un-directed edges, track all possible paths which end on a repeated node.
# +--- label the new nodes as you walk `[old label, steps to reach]`.
# +--- we'll call the repeated nodes `l`, and `l+`. We treat `l+` as a new node.
# +--- Combine all paths using the new labels to get `G~N`
# +---
fn unfold(seed: MGraph, origin: Int) -> MGraph:
    """Unfold the seed graph with respect to an origin node."""

    # width of the resulting graphs node table is the node count of the seed graph
    var width: Int = seed.node_count
    var result = MGraph(max(width, 1), width + 1, seed.history + origin)

    # if the seed graph is empty or does not contain the origin, give a single implicit self-loop.
    if width <= 0 or width < origin or origin < 1:
        result.unsafe_touch(Ind2(0, 0))
        result.finalize()
        return result^

    # else, this graph has reached step > 1; start crawling
    var depth: Int = 0
    var max_depth: Int = 0

    # add origin node
    var _o: Int = seed.lb2id(origin)
    result.touch(Ind2(_o, 0))

    # --- start crawling the seed graph, adding new nodes to this graph along the way
    # ---
    # --- when a node with at least one child which doesnt loop is reached, that childs index will be pushed onto the trace, and used to set the indexed mask true
    # --- when a node is reached where every child forms a loop, it's index will be popped from the trace, and used to set the indexed mask false
    # ---
    var trace: List[Int] = List[Int](capacity=depth)
    var mask = Array[Int](
        size=width
    )  # mask contains the depth the trace was at when the index was pushed, +1. if it has not been reached, 0.
    var edge_start: Int = 0  # the edge to start looping at
    var edge_limit: Int = 0  # the edge to stop looping at
    var o_: Int = _o

    @parameter  # --- check for continuation
    @always_inline
    fn _check() -> Bool:
        if mask[_o] > 0:
            result.reach(o_, _o, depth)
            return False  # loop encountered, return false
        return True  # keeps going, return true

    @parameter  # --- search through connected edges
    @always_inline
    fn _search() -> Bool:
        while _o < edge_limit:
            if seed.edges[Ind2(_o, o_)] > 0 and _check():
                result.reach(o_, _o, depth)
                return False  # check succeeded, continue deeper
            _o += 1
        return True  # all checks must fail to trigger a pop

    @parameter  # --- push trace, and update mask
    @always_inline
    fn _push():
        o_ = _o
        depth += 1
        mask[o_] = depth
        trace.append(o_)
        result.reach(o_, o_, depth)
        edge_start = seed.bounds[o_][0]
        edge_limit = seed.bounds[o_][1]
        _o = edge_start

    @parameter  # --- pop trace, and update mask
    @always_inline
    fn _pop():
        max_depth = max(depth, max_depth)  # check for max depth before pop
        depth -= 1  # decrement depth
        mask[o_] = 0  # set mask back to 0
        o_ = trace[max(0, depth - 1)]
        _o = trace.pop() + 1  # .. + 1 is so dont keep repeating the same _o after you pop!
        edge_start = seed.bounds[o_][0]
        edge_limit = seed.bounds[o_][1]

    # --- main crawl loop
    _push()
    while depth > 0:
        if _search():
            _pop()
        else:
            _push()

    _ = trace  # keep trace and mask alive for the duration of the crawl
    _ = mask  # ^
    # ---
    # ---
    # ------ end cawl

    # TODO debug / estimates error
    result.depth = max_depth + 1
    result.finalize()
    return result^


# +----------------------------------------------------------------------------------------------+ #
# | Unfolder Layer Graph
# +----------------------------------------------------------------------------------------------+ #
#
fn unfold_lg(seed: LGraph, origin: Int) -> LGraph:
    """Unfold the seed graph with respect to an origin node."""

    # width of the resulting graphs node table is the node count of the seed graph
    var width: Int = seed.node_count
    var result = LGraph(max(width, 1), width + 1, seed.history + origin)

    # if the seed graph is empty or does not contain the origin, give a single implicit self-loop.
    if width <= 0 or width < origin or origin < 1:
        result.unsafe_touch(Ind2(0, 0))
        result.finalize()
        return result^

    # else, this graph has reached step > 1. start crawling.

    # when a node with at least one child which doesnt loop is reached, that childs index will be pushed onto the trace, and used to set the indexed mask true
    # when a node is reached where every child forms a loop, it's index will be popped from the trace, and used to set the indexed mask false

    # trace describes the current walk through the seed graph.
    # it is a stack of x values corresponding to edges followed in the seed graph.
    # a positive x means you walked down the seed graph, a negative x means you walked up the seed graph
    var trace = List[Ind2](capacity=width)

    # mask contains booleans for every node in the seed graph
    # it gets set true if the node-id was reached in the current walk
    var mask = Vector[DType.bool, SpanBound.Unsafe](size=width)

    # add origin node
    var _lb = origin - 1
    var _xy = seed.lb2xy(_lb + 1)
    result.unsafe_touch(Ind2(_lb, 0))
    var lb_: Int
    var xy_: Ind2

    # +--- push trace, and update mask
    @parameter
    @always_inline
    fn _push():
        # search deepens, push trace
        xy_ = _xy
        lb_ = _lb
        result.reach(Ind2(lb_, len(trace)), lb_)
        trace.append(xy_)
        _xy = Ind2(0, xy_[1] - 1)
        mask[lb_] = True

    # --- pop trace, and update mask
    @parameter
    @always_inline
    fn _pop():
        # search ended, pop trace
        mask[lb_] = False
        _xy = trace.pop()
        _xy[0] += 1
        if len(trace) > 0:
            xy_ = trace[len(trace) - 1]
            lb_ = seed.xy2lb(xy_) - 1

    # +--- search through connected edges
    @parameter
    @always_inline
    fn _search() -> Bool:
        # search for neighbors until ready for push or pop
        while seed.next_neighbor(xy_, _xy):
            _lb = seed.xy2lb(_xy) - 1
            result.reach(Ind2(lb_, len(trace) - 1), _lb)
            if mask[_lb]:
                _xy[0] += 1
            else:
                return True
        return False

    # --- main crawl loop
    _push()
    while len(trace) > 0:
        if _search():
            _push()
        else:
            _pop()

    # keep trace and mask alive for the duration of the crawl
    _, _, _ = trace, mask, _xy

    # end cawl
    result.finalize()
    return result^


# +----------------------------------------------------------------------------------------------+ #
# | Unfolder Fast Breadth Layer Graph
# +----------------------------------------------------------------------------------------------+ #
#
# +--- This doesnt work
#
fn unfold_fast_breadth_lg[self_edge: Bool = True](seed: LGraph, origin: Int) -> LGraph:
    """Unfold the seed graph with respect to an origin node. (fast breadth) *This does not work."""

    # if the seed graph is empty or does not contain the origin, give a single implicit self-loop.
    if seed.node_count <= 0 or seed.node_count < origin or origin < 1:

        @parameter
        if self_edge:
            var result = LGraph(1, 1, seed.history + origin)
            result.unsafe_touch(Ind2(0, 0))
            result.finalize()
            return result^
        else:
            var result = LGraph(1, 2, seed.history + origin)
            result.unsafe_touch(Ind2(0, 0))
            result.reach(Ind2(0, 0), 0)
            result.finalize()
            return result^

    var result = LGraph(seed.node_count, seed.node_count + 1, seed.history + origin)
    var end = True

    # sets of integers representing the frequency of nodes reached for each layer in the new graph
    var curr_trace = Array[Freq[Int]](size=seed.node_count)
    var next_trace = Array[Freq[Int]](size=seed.node_count)

    # add origin node
    var xy = Ind2(origin, 0)
    result.unsafe_touch(xy)

    @parameter
    @always_inline
    fn _crawl_edges[above: Bool](curr_freq: Freq[Int]):
        for _x in range(seed.width):
            if seed.edges[_x, xy[0]][0 if above else 1] > 0:
                var _y = seed.id2xy(xy[0])[1] + (-1 if above else 1)
                var _id = seed.xy2id(Ind2(_x, _y))
                result.reach(xy, _id)
                var next_freq = Reference(next_trace[_id])
                if curr_freq[_id] < curr_freq.total:
                    end = False
                    next_freq[].total += curr_freq.total
                    next_freq[] += curr_freq
                    next_freq[] += DictEntry[Int, Int](xy[0], curr_freq.total)

    # crawl origin node
    @parameter
    if self_edge:
        result.reach(xy, xy[0])
    curr_trace[xy[0]].total = 1
    _crawl_edges[False](curr_trace[xy[0]])

    @parameter
    @always_inline
    fn _crawl_node(curr_freq: Freq[Int]):
        if curr_freq:
            _crawl_edges[True](curr_freq)

            @parameter
            if self_edge:
                result.reach(xy, xy[0])
            _crawl_edges[False](curr_freq)
        xy[0] += 1

    # crawl seed graph
    while not end:
        end = True
        xy[0] = 0
        xy[1] += 1
        swap(curr_trace, next_trace)
        for item in next_trace:
            item[].clear()
        while xy[0] < seed.node_count:
            _crawl_node(curr_trace[xy[0]])

    _, _, _ = curr_trace, next_trace, xy

    # end cawl
    result.finalize()
    return result^


# #------ Unfolder-Loop Rule ------#
# #---
# #--- nodes are considered self-edges
# #--- Starting at node `N` in graph `G`, and using directed edges, track all possible paths which end on a repeated node.
# #--- label the new nodes as you walk `[old label, steps to reach]`.
# #--- we'll call the repeated nodes `l`, and `l+`. We treat `l+` as a new node.
# #--- For each path, add a directed edge from `l+` to `l`.
# #--- Combine all paths using the new labels to get `G~N`
# #--- weights are unecessary
# #---
# #--- the result this process has, is basically extending every directed loop by 1, accounting for nodes being self-loops
# #--- however, there is a very small amount of variance with origin choice; [1,1,1,3] !~ [1,1,1,4], maybe this determines where you extended each loop from, that sounds about right
# #--- there is only ever one path to get from one node to another (without over repeating)
# #--- origin choice does not seem to affect node count, unlike regular unfolder
# #---
# #--- max_edge_out = GStep - 1
# #---
# fn unfold_loop(seed: Graph, origin: Int) -> Graph: #------ unfold the seed graph with respect to an origin node

#     var width: Int = seed.node_count # width of the resulting graph = node count of this graph

#     # if the seed graph is empty or does not contain origin, give the single (implicit) self-loop. (step 1)
#     if width <= 0 or width < origin or origin < 1:
#         return Graph(
#             seed.history.append(origin), #---- history
#             Table[Int](1,1,1), #------------------- nodes
#             Table[Int](1,1,0), #------------------- edges
#             Array[Int](1), #--------------------- weights
#             [Ind2(0,0)] #--------- _xy_id
#             )

#     # this graph has reached step > 1, start the crawling process
#     var depth: Int = 0
#     var max_depth: Int = 0
#     var node_count: Int = 0
#     var edge_count: Int = 0

#     # estimate size of resulting graph
#     var depth_est: Int = width + 1          #? edge estimate~ < seed edge_count * 3
#     var node_est: Int = width * depth_est   #? node estimate~ < seed count * 3

#     # create new containers for the resulting graph
#     var nodes = Table[Int](width, depth_est)
#     var edges = Table[Int](node_est, node_est)
#     var weights = Array[Int](size = node_est)
#     var _xy_id = Array[Ind2](size = node_est)

#     # add origin node
#     var _o: Int = seed.id_lb(origin)

#     _xy_id[node_count] = Ind2(_o,0)
#     node_count += 1
#     nodes[Ind2(_o,0)] = node_count
#     weights[0] += 1

#     #--- start crawling the seed graph, adding new nodes to this graph along the way
#     #---
#     #--- when a node with at least one child which doesnt loop is reached, that childs index will be pushed onto the trace, and used to set the indexed mask true
#     #--- when a node is reached where every child forms a loop, it's index will be popped from the trace, and used to set the indexed mask false
#     #---
#     var trace: List[Int] = List[Int](capacity = width)
#     var mask = Array[Int](size = width)   # mask contains the depth the trace was at when the index was pushed, +1. if it has not been reached, 0.
#     var edge_start: Int = 0               # the edge to start looping at
#     var edge_limit: Int = 0               # the edge to stop looping at
#     var o_: Int = _o

#     @parameter
#     fn _reach(): # the walk did not touch itself, try adding the reached node
#         var p_: Ind2 = Ind2(o_, depth - 1)
#         var _p: Ind2 = Ind2(_o, depth)
#         if nodes[_p] == 0:
#             _xy_id[node_count] = _p
#             node_count += 1
#             nodes[_p] = node_count
#         var i_: Int = nodes[p_] - 1
#         var _i: Int = nodes[_p] - 1
#         weights[_i] += 1
#         edges[Ind2(_i,i_)] += 1

#     @parameter #--- the check has completed a loop, add a previously unrealized node
#     fn _touch():
#         _reach()
#         var t_: Int = nodes[Ind2(_o, depth)] - 1
#         var _t: Int = nodes[Ind2(_o, mask[_o] - 1)] - 1
#         edges[Ind2(_t,t_)] += 1

#     @parameter #--- check for continuation
#     fn _check() -> Bool:
#         if mask[_o] > 0:
#             _touch()
#             return False # loop encountered, return false
#         return True # keeps going, return true

#     @parameter #--- search through connected edges
#     fn _search() -> Bool:
#         while _o < edge_limit:
#             if seed.edges[Ind2(_o,o_)] > 0 and _check():
#                 _reach()
#                 return False # check succeeded, continue deeper
#             _o += 1
#         return True # all checks must fail to trigger a pop

#     @parameter #--- push trace, and update mask
#     fn _push():
#         o_ = _o
#         depth += 1
#         mask[o_] = depth
#         trace.append(o_)
#         _touch()
#         edge_start = seed.bounds[o_][0]
#         edge_limit = seed.bounds[o_][1]
#         _o = edge_start

#     @parameter #--- pop trace, and update mask
#     fn _pop():
#         max_depth = max(depth, max_depth)  # check for max depth before pop
#         depth -= 1                         # decrement depth
#         mask[o_] = 0                       # set mask back to 0
#         o_ = trace[max(0,depth-1)]
#         _o = trace.pop() + 1          # .. + 1 is so dont keep repeating the same _o after you pop!
#         edge_start = seed.bounds[o_][0]
#         edge_limit = seed.bounds[o_][1]

#     @parameter #--- main crawl loop
#     fn _crawl():
#         _push()
#         while depth > 0:
#             if _search(): _pop() # search ended, pop trace
#             else: _push()       # search deepens, push trace

#     _crawl()
#     _ = trace # keep trace and mask alive for the duration of the crawl
#     _ = mask  # ^
#     depth = max_depth + 1
#     #---
#     #---
#     #------ end cawl

#     # TODO debug / estimates error

#     return Graph(
#         seed.history.append(origin),
#         Table[Int](width, depth, nodes),
#         Table[Int](node_count, node_count, edges),
#         weights.shrink(node_count),
#         _xy_id.shrink(node_count))
