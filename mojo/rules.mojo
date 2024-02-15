"""
Contains rules, and the means to follow them

Example: `follow[unfold]()`
"""

from math import min, max
from collections.vector import DynamicVector as List
from utils.index import StaticIntTuple as Ind
from array import Array
from table import Table, Row
from graph import Graph

alias Ind2 = Ind[2]




#------ Follow a history, using a rule (found below) ------#
#---
#--- nodes are considered self-edges
#---
fn follow[rule: fn(Graph,Int)->Graph](*history: Int) -> Graph: #--- follow origin history, and return the resulting graph at the end
    return follow[rule](history)

fn follow[rule: fn(Graph,Int)->Graph](history: Array[Int]) -> Graph:
    var result: Graph = Graph()
    for i in range(len(history)):
        result = rule(result,history[i])
    return result^




#------ Unfolder Rule ------#
#---
#--- nodes are considered self-edges
#---
#--- Starting at node `N` in graph `G`, and using un-directed edges, track all possible paths which end on a repeated node.
#--- label the new nodes as you walk `[old label, steps to reach]`.
#--- we'll call the repeated nodes `l`, and `l+`. We treat `l+` as a new node.
#--- Combine all paths using the new labels to get `G~N`
#---
fn unfold(seed: Graph, origin: Int) -> Graph: #------ unfold the seed graph with respect to an origin node
    
    let width: Int = seed.node_count # width of the resulting graph = node count of this graph
    
    # if the seed graph is empty or does not contain origin, give the single (implicit) self-loop. (step 1)
    if width <= 0 or width < origin or origin < 1:
        return Graph(
            Array[Int](seed.history, origin), #---- history
            Table[Int](1,1,1), #------------------- nodes
            Table[Int](1,1,0), #------------------- edges
            Array[Int](1,1), #--------------------- weights
            Array[Ind2](1,Ind2(0,0)) #--------- _xy_id
            )
    
    # this graph has reached step > 1, start the crawling process
    var depth: Int = 0
    var max_depth: Int = 0
    var node_count: Int = 0
    var edge_count: Int = 0
    
    # estimate size of resulting graph
    let depth_est: Int = width + 1          #? edge estimate~ < seed edge_count * 3
    let node_est: Int = width * depth_est   #? node estimate~ < seed count * 3
    
    # create new containers for the resulting graph
    var nodes: Table[Int] = Table[Int](width, depth_est)
    var edges: Table[Int] = Table[Int](node_est, node_est)
    var weights: Array[Int] = Array[Int](node_est)
    var _xy_id: Array[Ind2] = Array[Ind2](node_est)
    
    # add origin node
    var _o: Int = seed.id_lb(origin)
    
    _xy_id[node_count] = Ind2(_o,0)
    node_count += 1
    nodes[Ind2(_o,0)] = node_count
    weights[0] += 1
    
    #--- start crawling the seed graph, adding new nodes to this graph along the way
    #---
    #--- when a node with at least one child which doesnt loop is reached, that childs index will be pushed onto the trace, and used to set the indexed mask true
    #--- when a node is reached where every child forms a loop, it's index will be popped from the trace, and used to set the indexed mask false
    #---
    var trace: List[Int] = List[Int](width)
    var mask: Array[Int] = Array[Int](width)  # mask contains the depth the trace was at when the index was pushed, +1. if it has not been reached, 0.
    var edge_start: Int = 0                   # the edge to start looping at
    var edge_limit: Int = 0                   # the edge to stop looping at
    var o_: Int = _o
    
    @parameter #--- the walk did not touch itself, try adding the reached node
    fn _reach():
        let p_: Ind2 = Ind2(o_, depth - 1)
        let _p: Ind2 = Ind2(_o, depth)
        if nodes[_p] == 0:
            _xy_id[node_count] = _p
            node_count += 1
            nodes[_p] = node_count
        let i_: Int = nodes[p_] - 1
        let _i: Int = nodes[_p] - 1
        weights[_i] += 1
        edges[Ind2(_i,i_)] += 1
        edges[Ind2(i_,_i)] += 1

    @parameter #--- check for continuation
    fn _check() -> Bool:
        if mask[_o] > 0:
            _reach()
            return False # loop encountered, return false
        return True # keeps going, return true

    @parameter #--- search through connected edges
    fn _search() -> Bool:
        while _o < edge_limit:
            if seed.edges[Ind2(_o,o_)] > 0 and _check():
                _reach()
                return False # check succeeded, continue deeper
            _o += 1
        return True # all checks must fail to trigger a pop

    @parameter #--- push trace, and update mask
    fn _push():
        o_ = _o
        depth += 1
        mask[o_] = depth
        trace.push_back(o_)
        _reach()
        edge_start = seed.bounds[o_][0]
        edge_limit = seed.bounds[o_][1]
        _o = edge_start
        
    @parameter #--- pop trace, and update mask
    fn _pop():
        max_depth = max(depth, max_depth)  # check for max depth before pop
        depth -= 1                         # decrement depth
        mask[o_] = 0                       # set mask back to 0
        o_ = trace[max(0,depth-1)]
        _o = trace.pop_back() + 1          # .. + 1 is so dont keep repeating the same _o after you pop!
        edge_start = seed.bounds[o_][0]
        edge_limit = seed.bounds[o_][1]

    @parameter #--- main crawl loop
    fn _crawl():
        _push()
        while depth > 0:
            if _search(): _pop() # search ended, pop trace
            else: _push()       # search deepens, push trace
        
    _crawl()
    _ = trace # keep trace and mask alive for the duration of the crawl
    _ = mask  # ^
    depth = max_depth + 1
    #---
    #---
    #------ end cawl

    # TODO debug / estimates error
    
    return Graph(
        Array[Int](seed.history, origin),
        Table[Int](width, depth, nodes),
        Table[Int](node_count, node_count, edges),
        Array[Int](node_count, weights),
        Array[Ind2](node_count, _xy_id))




#------ Unfolder-Loop Rule ------#
#---
#--- nodes are considered self-edges
#--- Starting at node `N` in graph `G`, and using directed edges, track all possible paths which end on a repeated node.
#--- label the new nodes as you walk `[old label, steps to reach]`.
#--- we'll call the repeated nodes `l`, and `l+`. We treat `l+` as a new node.
#--- For each path, add a directed edge from `l+` to `l`.
#--- Combine all paths using the new labels to get `G~N`
#--- weights are unecessary
#---
#--- the result this process has, is basically extending every directed loop by 1, accounting for nodes being self-loops
#--- however, there is a very small amount of variance with origin choice; [1,1,1,3] !~ [1,1,1,4], maybe this determines where you extended each loop from, that sounds about right
#--- there is only ever one path to get from one node to another (without over repeating)
#--- origin choice does not seem to affect node count, unlike regular unfolder
#---
#--- max_edge_out = GStep - 1
#---
fn unfold_loop(seed: Graph, origin: Int) -> Graph: #------ unfold the seed graph with respect to an origin node
    
    let width: Int = seed.node_count # width of the resulting graph = node count of this graph
    
    # if the seed graph is empty or does not contain origin, give the single (implicit) self-loop. (step 1)
    if width <= 0 or width < origin or origin < 1:
        return Graph(
            Array[Int](seed.history, origin), #---- history
            Table[Int](1,1,1), #------------------- nodes
            Table[Int](1,1,0), #------------------- edges
            Array[Int](1,1), #--------------------- weights
            Array[Ind2](1,Ind2(0,0)) #--------- _xy_id
            )
    
    # this graph has reached step > 1, start the crawling process
    var depth: Int = 0
    var max_depth: Int = 0
    var node_count: Int = 0
    var edge_count: Int = 0
    
    # estimate size of resulting graph
    let depth_est: Int = width + 1          #? edge estimate~ < seed edge_count * 3
    let node_est: Int = width * depth_est   #? node estimate~ < seed count * 3
    
    # create new containers for the resulting graph
    var nodes: Table[Int] = Table[Int](width, depth_est)
    var edges: Table[Int] = Table[Int](node_est, node_est)
    var weights: Array[Int] = Array[Int](node_est)
    var _xy_id: Array[Ind2] = Array[Ind2](node_est)
    
    # add origin node
    var _o: Int = seed.id_lb(origin)
    
    _xy_id[node_count] = Ind2(_o,0)
    node_count += 1
    nodes[Ind2(_o,0)] = node_count
    weights[0] += 1
    
    #--- start crawling the seed graph, adding new nodes to this graph along the way
    #---
    #--- when a node with at least one child which doesnt loop is reached, that childs index will be pushed onto the trace, and used to set the indexed mask true
    #--- when a node is reached where every child forms a loop, it's index will be popped from the trace, and used to set the indexed mask false
    #---
    var trace: List[Int] = List[Int](width)
    var mask: Array[Int] = Array[Int](width)  # mask contains the depth the trace was at when the index was pushed, +1. if it has not been reached, 0.
    var edge_start: Int = 0                   # the edge to start looping at
    var edge_limit: Int = 0                   # the edge to stop looping at
    var o_: Int = _o
    
    @parameter
    fn _reach(): # the walk did not touch itself, try adding the reached node
        let p_: Ind2 = Ind2(o_, depth - 1)
        let _p: Ind2 = Ind2(_o, depth)
        if nodes[_p] == 0:
            _xy_id[node_count] = _p
            node_count += 1
            nodes[_p] = node_count
        let i_: Int = nodes[p_] - 1
        let _i: Int = nodes[_p] - 1
        weights[_i] += 1
        edges[Ind2(_i,i_)] += 1

    @parameter #--- the check has completed a loop, add a previously unrealized node
    fn _touch():
        _reach()
        let t_: Int = nodes[Ind2(_o, depth)] - 1
        let _t: Int = nodes[Ind2(_o, mask[_o] - 1)] - 1
        edges[Ind2(_t,t_)] += 1

    @parameter #--- check for continuation
    fn _check() -> Bool:
        if mask[_o] > 0:
            _touch()
            return False # loop encountered, return false
        return True # keeps going, return true

    @parameter #--- search through connected edges
    fn _search() -> Bool:
        while _o < edge_limit:
            if seed.edges[Ind2(_o,o_)] > 0 and _check():
                _reach()
                return False # check succeeded, continue deeper
            _o += 1
        return True # all checks must fail to trigger a pop
    
    @parameter #--- push trace, and update mask
    fn _push():
        o_ = _o
        depth += 1
        mask[o_] = depth
        trace.push_back(o_)
        _touch()
        edge_start = seed.bounds[o_][0]
        edge_limit = seed.bounds[o_][1]
        _o = edge_start
        
    @parameter #--- pop trace, and update mask
    fn _pop():
        max_depth = max(depth, max_depth)  # check for max depth before pop
        depth -= 1                         # decrement depth
        mask[o_] = 0                       # set mask back to 0
        o_ = trace[max(0,depth-1)]
        _o = trace.pop_back() + 1          # .. + 1 is so dont keep repeating the same _o after you pop!
        edge_start = seed.bounds[o_][0]
        edge_limit = seed.bounds[o_][1]

    @parameter #--- main crawl loop
    fn _crawl():
        _push()
        while depth > 0:
            if _search(): _pop() # search ended, pop trace
            else: _push()       # search deepens, push trace

    _crawl()
    _ = trace # keep trace and mask alive for the duration of the crawl
    _ = mask  # ^
    depth = max_depth + 1
    #---
    #---
    #------ end cawl

    # TODO debug / estimates error
    
    return Graph(
        Array[Int](seed.history, origin),
        Table[Int](width, depth, nodes),
        Table[Int](node_count, node_count, edges),
        Array[Int](node_count, weights),
        Array[Ind2](node_count, _xy_id))