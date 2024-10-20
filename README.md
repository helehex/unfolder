# unfolder
Graph crawling automata.

You can find this rule on OEIS: https://oeis.org/A376148

### The main focus of this repo is walk-union graph update rules:
- Start with a graph `G`.
- Pick an origin node `o` in graph `G`.
- Find all walks which start at node `o` and independently repeat exactly one node.
- Label the nodes for each walk `[old label, substeps to reach]`.
- Take the temporally sensitive union all walks to get the resulting graph `G-o`.

> Nodes are considered self-edges by default.
> All edges are considered undirected by default.
> "Substep" means traversing one edge for every walk.

### This gives a special asynchronous property:
- the next step `G-o1-o2` can be started once `G-o1` has reached the substep which includes `o2`
- choosing a stationary origin allows you to start steps more frequently

### Examples:

![Image of a step 6 variant](/res/images/example_0.png)

![Image of a step 6 variant](/res/images/example_1.png)