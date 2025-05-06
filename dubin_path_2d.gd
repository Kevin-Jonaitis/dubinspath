extends Node2D ## THIS SHOULD NOT BE A NODE. It's just a data countainer, so we should use resource? or refcounted mayBe?
# We need to fix this so we're not drawing on the node
class_name DubinPath2D

var drawableFunctionsToCallLater: Array[Callable] = []
var shortest_path: DubinPath
# Should probably clear this once the shortest path is found
# Maybe can clear it when the user isn't asking to draw all the paths
var paths: Array[DubinPath] = []

## Use images here point names and thetas refererd to:
## https://www.habrador.com/tutorials/unity-dubins-paths/2-basic-dubins-paths/

func compute_dubin_paths(start_pos: Vector2, start_angle: float, end_pos: Vector2, end_angle: float, min_turn_radius: float) -> Array[DubinPath]:
	if start_pos == end_pos and Utils.check_angle_matches(start_angle,end_angle):
		return []
	return DubinsPathMath.compute_dubins_paths(start_pos, start_angle, end_pos, end_angle, min_turn_radius)

## Maybe should store passed in variables?
func calculate_and_draw_paths(start_pos: Vector2, start_angle: float, end_pos: Vector2, end_angle: float, min_turn_radius: float, draw_paths: bool) -> bool:
	# If the start and end are the same, we don't need to move at all. Short-circuit everything. The shortest
	# path is standing still. If you really want to calculate this path, just draw a circle(in your perferred direction)
	# ending at this point. The below code freaks out because of direction of rotation and floating point precision
	# issues, so gives incosistent results depending on where you start and end. These issues arn't worth figuring out,
	# because even if I did they'd give some arbitrary result that you probably wouldn't want anyways.

	if start_pos == end_pos and Utils.check_angle_matches(start_angle,end_angle):
		clear_drawables()
		return false
	self.paths = DubinsPathMath.compute_dubins_paths(start_pos, start_angle, end_pos, end_angle, min_turn_radius)
	# Technically, we should never return a path size of 0. Dubins paths are always valid.
	# The only time this really happens
	# is if the starting point is also the ending point. Maybe the user wants to draw this
	# a big circle, but they have other ways to do that(split it into 2 half circles). So in this case
	# we're just going to return no path found. We might revisit this later.
	if (paths.size() == 0):
		print("NO PATHS FOUND")
		return false
	self.shortest_path = DubinsPathMath.get_shortest_dubin_path(paths)
	if (draw_paths):
		draw_tangent_circles(start_pos, start_angle, end_pos, end_angle, min_turn_radius)
		draw_dubin_paths()
		draw_path(shortest_path, Color.WHITE)
		queue_redraw()
	return true;


func draw_dubin_paths() -> void:
	var path_colors: Array[Color] = [Color.PURPLE, Color.AQUA, Color.BLACK, Color.YELLOW, Color.ORANGE, Color.GREEN]
	var color_index: int = 0;
	for path: DubinPath in paths:
		draw_path(path, path_colors[color_index])
		color_index += 1

func clear_drawables() -> void:
	drawableFunctionsToCallLater.clear()
	queue_redraw()

func draw_path(path: DubinPath, color: Color) -> void:
	if (path.get_points().size() < 2):
		print("WE HAVE TOO SHORT OF A PATH")
	drawableFunctionsToCallLater.append(
				func() -> void: draw_polyline(PackedVector2Array(path.get_points()), color, 3))

# Function to draw two circles based on tangent, radius, and point
func draw_tangent_circles(start_pos: Vector2, start_angle: float, end_pos: Vector2, end_angle: float, radius: float) -> void:

	var circles_start: DubinsPathMath.TangentCircles = DubinsPathMath.get_perpendicular_circle_centers(start_pos, start_angle, radius)
	var circles_end: DubinsPathMath.TangentCircles = DubinsPathMath.get_perpendicular_circle_centers(end_pos, end_angle, radius)

	# Draw the circles
	drawableFunctionsToCallLater.append(
		func() -> void: draw_circle(circles_start.left.center, radius, Color.RED, false, 2))
	drawableFunctionsToCallLater.append(
		func() -> void: draw_circle(circles_start.right.center, radius, Color.BLUE, false, 2))
	drawableFunctionsToCallLater.append(
		func() -> void: draw_circle(circles_end.left.center, radius, Color.RED, false, 2))
	drawableFunctionsToCallLater.append(
		func() -> void: draw_circle(circles_end.right.center, radius, Color.BLUE, false, 2))

func _draw() -> void:
	for function: Callable in drawableFunctionsToCallLater:
		function.call()
	drawableFunctionsToCallLater.clear()
