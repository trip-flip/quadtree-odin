package quadtree

Point :: [2]f32

Rect :: struct {
	min: Point,
	max: Point,
}

center :: proc(r: Rect) -> Point {
	half_length_x := (r.max.x - r.min.x) / 2
	half_length_y := (r.max.y - r.min.y) / 2

	return Point{r.min.x + half_length_x, r.min.y + half_length_y}
}

contains_point :: proc(r: Rect, p: Point) -> bool {
	min := r.min
	max := r.max

	if min.x <= p.x && min.y <= p.y && max.x >= p.x && max.y >= p.y {
		return true
	}

	return false
}

intersects_rect :: proc(r1: Rect, r2: Rect) -> bool {
	if r1.min.x <= r2.max.x &&
	   r1.max.x >= r2.min.x &&
	   r1.min.y <= r2.max.y &&
	   r1.max.y >= r2.min.y {
		return true
	}

	return false
}

// Node referring to the regions making up the quadtree.
// Cap referring to the max capacity of points in a region.
NODE_CAP :: 4

Quadtree :: struct {
	boundary:   Rect,
	points:     [dynamic]Point,

	// Cardinal directions
	north_west: ^Quadtree,
	north_east: ^Quadtree,
	south_west: ^Quadtree,
	south_east: ^Quadtree,
}

// Creates a quadtree on the heap.
new_quadtree :: proc(boundary: Rect) -> (qt: ^Quadtree) {
	qt = new(Quadtree)
	qt.boundary = boundary
	qt.points = make([dynamic]Point)
	qt.north_west = nil
	qt.north_east = nil
	qt.south_west = nil
	qt.south_east = nil

	return
}

// Must be called when you are done with quadtree, frees the memory.
free_quadtree :: proc(qt: ^Quadtree) {
	defer free(qt)

	delete(qt.points)

	if qt.north_west == nil {
		return
	}

	free_quadtree(qt.north_west)
	free_quadtree(qt.north_east)
	free_quadtree(qt.south_west)
	free_quadtree(qt.south_east)
}

insert :: proc(qt: ^Quadtree, p: Point) -> bool {
	if !contains_point(qt.boundary, p) {
		return false
	}

	if len(qt.points) < NODE_CAP && qt.north_west == nil {
		append(&qt.points, p)
		return true
	}

	if qt.north_west == nil {
		subdivide(qt)
	}

	if insert(qt.north_west, p) do return true
	if insert(qt.north_east, p) do return true
	if insert(qt.south_west, p) do return true
	if insert(qt.south_east, p) do return true

	return false
}

query_range :: proc(qt: ^Quadtree, range: Rect) -> [dynamic]Point {
	points_in_range := [dynamic]Point{}

	if !intersects_rect(qt.boundary, range) {
		return points_in_range
	}

	for p in qt.points {
		if contains_point(range, p) {
			append(&points_in_range, p)
		}
	}

	if qt.north_west == nil {
		return points_in_range
	}

	points: [dynamic]Point

	points = query_range(qt.north_west, range)
	for p in points {
		append(&points_in_range, p)
	}
	delete(points)

	points = query_range(qt.north_east, range)
	for p in points {
		append(&points_in_range, p)
	}
	delete(points)

	points = query_range(qt.south_west, range)
	for p in points {
		append(&points_in_range, p)
	}
	delete(points)

	points = query_range(qt.south_east, range)
	for p in points {
		append(&points_in_range, p)
	}
	delete(points)

	return points_in_range
}

// Helper function for when there are too many points in a node.
subdivide :: proc(qt: ^Quadtree) {
	center := center(qt.boundary)

	rect: Rect

	rect.min.x = qt.boundary.min.x
	rect.min.y = qt.boundary.min.y
	rect.max.x = center.x
	rect.max.y = center.y
	qt.north_west = new_quadtree(rect)

	rect.min.x = center.x
	rect.min.y = qt.boundary.min.y
	rect.max.x = qt.boundary.max.x
	rect.max.y = center.y
	qt.north_east = new_quadtree(rect)

	rect.min.x = qt.boundary.min.x
	rect.min.y = center.y
	rect.max.x = center.x
	rect.max.y = qt.boundary.max.y
	qt.south_west = new_quadtree(rect)

	rect.min.x = center.x
	rect.min.y = center.y
	rect.max.x = qt.boundary.max.x
	rect.max.y = qt.boundary.max.y
	qt.south_east = new_quadtree(rect)

	for p in qt.points {
		if insert(qt.north_west, p) do continue
		if insert(qt.north_east, p) do continue
		if insert(qt.south_west, p) do continue
		if insert(qt.south_east, p) do continue
	}

	clear(&qt.points)
}

import "core:testing"

@(test)
make_then_insert_then_query :: proc(t: ^testing.T) {
	qt := new_quadtree(Rect{Point{0, 0}, Point{1920, 1080}})
	defer free_quadtree(qt)

	insert(qt, Point{1, 1})
	points := query_range(qt, Rect{Point{0, 0}, Point{1920, 1080}})
	defer delete(points)

	testing.expect_value(t, len(points), 1)
	testing.expect_value(t, points[0], Point{1, 1})
}

@(test)
insert_five_and_get_one :: proc(t: ^testing.T) {
	qt := new_quadtree(Rect{Point{0, 0}, Point{1920, 1080}})
	defer free_quadtree(qt)

	insert(qt, Point{100, 100})
	insert(qt, Point{1500, 900})
	insert(qt, Point{100, 900})
	insert(qt, Point{1500, 100})
	insert(qt, Point{1920 / 2, 1080 / 2})

	points := query_range(qt, Rect{{90, 90}, {110, 110}})
	defer delete(points)

	testing.expect_value(t, len(points), 1)
	testing.expect_value(t, points[0], Point{100, 100})
}

@(test)
insert_five_and_get_five :: proc(t: ^testing.T) {
	qt := new_quadtree(Rect{Point{0, 0}, Point{1920, 1080}})
	defer free_quadtree(qt)

	insert(qt, Point{100, 100})
	insert(qt, Point{1500, 900})
	insert(qt, Point{100, 900})
	insert(qt, Point{1500, 100})
	insert(qt, Point{1920 / 2, 1080 / 2})

	points := query_range(qt, Rect{{0, 0}, {1920, 1080}})
	defer delete(points)

	testing.expect_value(t, len(points), 5)
}

@(test)
insert_five_and_get_three :: proc(t: ^testing.T) {
	qt := new_quadtree(Rect{Point{0, 0}, Point{1920, 1080}})
	defer free_quadtree(qt)

	insert(qt, Point{20, 20})
	insert(qt, Point{40, 40})
	insert(qt, Point{60, 60})
	insert(qt, Point{80, 80})
	insert(qt, Point{100, 00})

	points := query_range(qt, Rect{{0, 0}, {60, 60}})
	defer delete(points)

	testing.expect_value(t, len(points), 3)
}
