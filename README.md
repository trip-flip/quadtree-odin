# Quadtree Library for Odin

Based off of the [Wikipedia implmentation](https://en.wikipedia.org/wiki/Quadtree). There's some basic testing in it, but I'm not sure of best practices here. It seems to work
fine though :).

## Install and Usage

Clone the repo into your project. It should be stored in a directory called `quadtree`, which you can import. Here's some example usage below:

```odin
import qt "quadtree"

main :: proc() {
	qt := qt.new_quadtree(Rect{Point{0, 0}, Point{1920, 1080}}) // Allocated on the heap
	defer qt.free_quadtree(qt)

	qt.insert(qt, Point{20, 20})
	qt.insert(qt, Point{40, 40})
	qt.insert(qt, Point{60, 60})
	qt.insert(qt, Point{80, 80})
	qt.insert(qt, Point{100, 00})

	// `points` should have three points: (20 20), (40 40), and (60 60).
	// `points` also needs to be deallocated too.
	points := qt.query_range(qt, Rect{{0, 0}, {60, 60}})
	defer delete(points)

	// Rest of code....
}
```
