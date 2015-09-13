Just a public repo for showing/sharing code over the next day or so.

Plans on the Sudoku solver:

Now that I have the basic board representation and rules working, I want to implement various solution strategies. I probably will implement them AS strategy objects (the strategy design pattern, that is). Essentially, we can sequentially scan the cells for certain "useful" patterns. The simplest of these is the "naked singleton" -- a cell where the candidates list includes only one value. Since there's only one value possible, we simply solve the cell with that value. Much more complex strategies exist, however. For instance, if two cells aligned in a column are the only cells in a box that can contain a given value, then we know -- without having to know which of the two it is -- no other cell in that column can contain that value. So by a process of iterative refinement, applying various strategies like these, we can reduce the number of candidates for each unsolved cell until it either becomes solved (because no other choice is possible) or reduces to a naked singleton as a result of another cell's candidates changing.

This will require another data structure, or refinement on the current data structure. The current data structure reflects how things *are*, not how they *might be*. Perhaps a clone, a chain of potential Board objects, each with links to the one from which it came? Then we can implement a backtracking solver by solving until we reach a place where no more candidate reductions/cell solves are possible, and unless we've won, then backtracking until the last inflection point?

Have to think about this algorithmically a bit. I'm sure I'll come up with a naive solution and then be able to factor it down into something with decent performance characteristics in space and time.