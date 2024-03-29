# unfolder
Graph crawling automata.

> Graph with history `1-2-2-2-2-2`, aka. `1A5B`, and a highlighted sub-region
![Image of a step 6 variant](/res/images/graphstuffi.png)

### The main focus of this repo is the following graph update rule:
- Start with a graph `G`.
- Pick an origin node `o` in graph `G`.
- Find all walks which start at node `o`, and repeat exactly one node.
- Label the nodes for each walk `[old label, substeps to reach]`.
- Union all walks using the new labels to get `G-o`.

> Nodes are considered self-edges through time.  
> "Substep" means traversing one edge for every walk.

### This gives a special asynchronous property:
- the next step `G-o1-o2` can be started once `G-o1` has reached the substep which includes `o2`
- choosing a stationary origin allows you to start steps more frequently
