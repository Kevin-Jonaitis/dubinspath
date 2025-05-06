extends RefCounted
class_name DubinsPathMath

const MIN_RADIUS: float = 0.0
const POINTS: Array = []
const CURVATURES: Array = []
const PATH_TYPES: Array[String] = ["LSL", "RSR", "LSR", "RSL", "RLR", "LRL"]

## Use images here point names and thetas refererd to:
## https://www.habrador.com/tutorials/unity-dubins-paths/2-basic-dubins-paths/
class TangentCircles:
	var left: CircleInfo
	var right: CircleInfo
	func _init(_left: CircleInfo, _right: CircleInfo) -> void:
		self.left = _left
		self.right = _right

class CircleInfo:
	var center: Vector2
	## This is the angle from the center of this circle
	## to the point where the track starts/ends
	var center_theta: float
	# The angle of the unit tangent at the point w.r.t. x-axis that is used to construct the left and right cicles
	var theta: float 

	# Constructor
	func _init(_center: Vector2, center_theta_: float, theta_: float) -> void:
		self.center = _center
		self.center_theta = center_theta_
		self.theta = theta_

## Fetches the center of the left and right circles
## and the angles pointing from the center of the circle to point
static func get_perpendicular_circle_centers(point: Vector2, angle: float, radius: float) -> TangentCircles:
	# Calculate the perpendicular directions based on the angle in a left-handed system
	var left_tangent_angle: float = angle + PI / 2  # Rotate 90 degrees clockwise
	var right_tangent_angle: float = angle - PI / 2  # Rotate 90 degrees counterclockwise

	# Calculate the tangent directions
	var left_tangent: Vector2 = Vector2(cos(left_tangent_angle), sin(left_tangent_angle))
	var right_tangent: Vector2 = Vector2(cos(right_tangent_angle), sin(right_tangent_angle))

	# Calculate the centers of the circles
	var left_circle_center: Vector2 = point - left_tangent * radius
	var right_circle_center: Vector2 = point - right_tangent * radius

	# Create and return the result
	return TangentCircles.new(
		CircleInfo.new(left_circle_center, left_tangent_angle, angle),
		CircleInfo.new(right_circle_center, right_tangent_angle, angle)
	)
# Inputs:
# start_pos: Vector2 - starting position (x, y)
# start_dir: Vector2 - starting direction (unit vector)
# end_pos: Vector2 - ending position (x, y)
# end_dir: Vector2 - ending direction (unit vector)
# min_turn_radius: float - minimum turning radius
static func compute_dubins_paths(start_pos: Vector2, start_angle: float, end_pos: Vector2, end_angle: float, min_turn_radius: float) -> Array[DubinPath]:
	# var path_types = ["LSR"]

	var paths: Array[DubinPath] = []
	
	var circles_start: TangentCircles = get_perpendicular_circle_centers(start_pos, start_angle, min_turn_radius)
	var circles_end: TangentCircles = get_perpendicular_circle_centers(end_pos, end_angle, min_turn_radius)

	for path_type: String in PATH_TYPES:
		var path: DubinPath = compute_path(min_turn_radius, path_type, circles_start, circles_end)
		if (path == null || path.segments.size() == 0): # Check to see if we actually found a path
			continue
		paths.append(path)
	return paths

static func get_shortest_dubin_path(paths: Array[DubinPath]) -> DubinPath:
	var shortest_path: DubinPath = null
	var shortest_length: float = INF
	for path: DubinPath in paths:
		if path.length < shortest_length:
			shortest_path = path
			shortest_length = path.length
	return shortest_path


## Should run computation with different radius' R(mouse scroll wheel to adjust?)
static func compute_path(r: float, path_type: String, start_circles: TangentCircles, end_circles: TangentCircles) -> DubinPath:
	match path_type:
		pass
		"LSL":
			return dubins_LSL(start_circles.left, end_circles.left, false, r)
		"RSR":
			return dubins_RSR(start_circles.right, end_circles.right, true, r)
		"LSR":
			return dubins_LSR(start_circles.left, end_circles.right, r)
		"RSL":
			return dubins_RSL(start_circles.right, end_circles.left, r)
		"RLR":
			return dubins_RLR(start_circles.right, end_circles.right, r)
		"LRL":
			return dubins_LRL(start_circles.left, end_circles.left, r)
	return null
	
static func dubins_LSL(start: CircleInfo, end: CircleInfo, clockwise: bool, radius: float) -> DubinPath:
	var A: Vector2 = start.center
	var D: Vector2 = end.center
	var AD: Vector2 = D - A
	var theta: float = atan2(AD.y, AD.x)
	var AS_theta: float = start.center_theta
	var DF_theta: float = end.center_theta
	
	var AB_theta: float = theta + (PI / 2.0) # Difference
	var B: Vector2 = Vector2(A.x + radius * cos(AB_theta), A.y + radius * sin(AB_theta))
	var C: Vector2 = B + AD
	AB_theta = adjust_end_theta(AS_theta, AB_theta, clockwise)
	DF_theta = adjust_end_theta(AB_theta, end.center_theta, clockwise)

	var startArc: DubinPath.Arc = DubinPath.Arc.new(A, AS_theta, AB_theta, radius)
	## We flop start and end points around because we are ending at the tagent direciton of travel, rather than starting at it
	#B_theta should be the same as C_theta
	var endArc: DubinPath.Arc = DubinPath.Arc.new(D, AB_theta, DF_theta, radius)

	return DubinPath.new("LSL", [startArc, DubinPath.Line.new(B, C), endArc], start.theta, end.theta)

static func dubins_RSR(start: CircleInfo, end: CircleInfo, clockwise: bool, radius: float) -> DubinPath:
	var A: Vector2 = start.center
	var D: Vector2 = end.center
	var AD: Vector2 = D - A
	var theta: float = atan2(AD.y, AD.x)
	var AS_theta: float = start.center_theta
	var DF_theta: float = end.center_theta

	var AB_theta: float = theta - (PI / 2.0) # Difference
	var B: Vector2 = Vector2(A.x + radius * cos(AB_theta), A.y + radius * sin(AB_theta))
	var C: Vector2 = B + AD

	AB_theta = adjust_end_theta(AS_theta, AB_theta, clockwise)
	DF_theta = adjust_end_theta(AB_theta, end.center_theta, clockwise)
	
	var startArc: DubinPath.Arc = DubinPath.Arc.new(A, AS_theta, AB_theta, radius)
	## We flop start and end points around because we are ending at the tagent direciton of travel, rather than starting at it
	#B_theta should be the same as C_theta
	var endArc: DubinPath.Arc = DubinPath.Arc.new(D, AB_theta, DF_theta, radius)

	return DubinPath.new("RSR", [startArc, DubinPath.Line.new(B, C), endArc], start.theta, end.theta)

static func dubins_LSR(start: CircleInfo, end: CircleInfo, radius: float) -> DubinPath:
	if (start.center.distance_to(end.center) < radius * 2):
		return null

	var A: Vector2 = start.center
	var D: Vector2 = end.center
	var AD: Vector2 = D - A
	var theta: float = acos(2 * radius / AD.length())
	var arctan2_theta: float = atan2(AD.y, AD.x) ## Different
	var AB_theta: float = theta + arctan2_theta
	var B: Vector2 = Vector2(A.x + radius * cos(AB_theta), A.y + radius * sin(AB_theta))
	var C: Vector2 = Vector2(A.x + 2 * radius * cos(AB_theta), A.y + 2 * radius * sin(AB_theta))
	var CD: Vector2 = D - C
	var E: Vector2 = B + CD

	var AS_theta: float = start.center_theta
	var DF_theta: float = end.center_theta
	var DE_theta: float = AB_theta + PI

	AB_theta = adjust_end_theta(AS_theta, AB_theta, false) ## Swapped direction
	DF_theta = adjust_end_theta(DE_theta, DF_theta, true) ## Swapped direction

	var startArc: DubinPath.Arc = DubinPath.Arc.new(A, AS_theta, AB_theta, radius)
	var endArc: DubinPath.Arc = DubinPath.Arc.new(D, DE_theta, DF_theta, radius)

	return DubinPath.new("LSR", [startArc, DubinPath.Line.new(B, E), endArc], start.theta, end.theta)

static func dubins_RSL(start: CircleInfo, end: CircleInfo, radius: float) -> DubinPath:
	if (start.center.distance_to(end.center) < radius * 2):
		return null

	var A: Vector2 = start.center
	var D: Vector2 = end.center
	var AD: Vector2 = D - A
	var theta: float = acos(2 * radius / AD.length())
	var arctan2_theta: float = atan2(AD.y, AD.x)
	var AB_theta: float = -theta + arctan2_theta
	var B: Vector2 = Vector2(A.x + radius * cos(AB_theta), A.y + radius * sin(AB_theta))
	var C: Vector2 = Vector2(A.x + 2 * radius * cos(AB_theta), A.y + 2 * radius * sin(AB_theta))
	var CD: Vector2 = D - C
	var E: Vector2 = B + CD

	var AS_theta: float = start.center_theta
	var DF_theta: float = end.center_theta
	var DE_theta: float = AB_theta + PI

	AB_theta = adjust_end_theta(AS_theta, AB_theta, true)
	DF_theta = adjust_end_theta(DE_theta, DF_theta, false)

	var startArc: DubinPath.Arc = DubinPath.Arc.new(A, AS_theta, AB_theta, radius)
	var endArc: DubinPath.Arc = DubinPath.Arc.new(D, DE_theta, DF_theta, radius)

	return DubinPath.new("RSL", [startArc, DubinPath.Line.new(B, E), endArc], start.theta, end.theta)


## Different from LRL only that we change the circles we pass in and the rotation direction around
## the circles
static func dubins_RLR(start: CircleInfo, end: CircleInfo, radius: float) -> DubinPath:
	if (start.center.distance_to(end.center) > radius * 4):
		return null

	var A: Vector2 = start.center
	var B: Vector2 = end.center
	var AB: Vector2 = B - A
	var theta: float = acos(AB.length() / (4 * radius))
	var AB_theta: float = atan2(AB.y, AB.x)
	var AC_theta: float = AB_theta - theta
	var C: Vector2 = Vector2(A.x + 2 * radius * cos(AC_theta), A.y + 2 * radius * sin(AC_theta))
	var CB: Vector2 = B - C
	var AC: Vector2 = C - A

	var AS_theta: float = start.center_theta
	AC_theta = adjust_end_theta(AS_theta, AC_theta, true)
	var startArc: DubinPath.Arc = DubinPath.Arc.new(A, AS_theta, AC_theta, radius)

	var CA_theta: float = atan2(-AC.y, -AC.x)
	var CB_theta: float = atan2(CB.y, CB.x)

	CB_theta = adjust_end_theta(CA_theta, CB_theta, false)
	var middle_arc: DubinPath.Arc = DubinPath.Arc.new(C, CA_theta, CB_theta, radius)

	var BC_theta: float = atan2(-CB.y, -CB.x)
	var BE_theta: float = end.center_theta
	BE_theta = adjust_end_theta(BC_theta, BE_theta, true)
	var end_arc: DubinPath.Arc = DubinPath.Arc.new(B, BC_theta, BE_theta, radius)

	return DubinPath.new("RLR", [startArc, middle_arc, end_arc], start.theta, end.theta)

static func dubins_LRL(start: CircleInfo, end: CircleInfo, radius: float) -> DubinPath:
	if (start.center.distance_to(end.center) > radius * 4):
		return null

	var A: Vector2 = start.center
	var B: Vector2 = end.center
	var AB: Vector2 = B - A
	var theta: float = acos(AB.length() / (4 * radius))
	var AB_theta: float = atan2(AB.y, AB.x)
	var AC_theta: float = AB_theta + theta # Different
	var C: Vector2 = Vector2(A.x + 2 * radius * cos(AC_theta), A.y + 2 * radius * sin(AC_theta))
	var CB: Vector2 = B - C
	var AC: Vector2 = C - A

	var AS_theta: float = start.center_theta
	AC_theta = adjust_end_theta(AS_theta, AC_theta, false)
	var startArc: DubinPath.Arc = DubinPath.Arc.new(A, AS_theta, AC_theta, radius)

	var CA_theta: float = atan2(-AC.y, -AC.x)
	var CB_theta: float = atan2(CB.y, CB.x)

	CB_theta = adjust_end_theta(CA_theta, CB_theta, true)
	var middle_arc: DubinPath.Arc = DubinPath.Arc.new(C, CA_theta, CB_theta, radius)

	var BC_theta: float = atan2(-CB.y, -CB.x)
	var BE_theta: float = end.center_theta
	BE_theta = adjust_end_theta(BC_theta, BE_theta, false)
	var end_arc: DubinPath.Arc = DubinPath.Arc.new(B, BC_theta, BE_theta, radius)

	return DubinPath.new("LRL", [startArc, middle_arc, end_arc], start.theta, end.theta)

## Adjust the thetas so that they're in an order that draws them correctly according to the
## direction of travel
## Note that you may have to add tau multiple times to get the ordering so that one is before the other
## because the angles might be seperated by more than 2PI, e.g. -1.5PI and 1.5PI
## Finally squish the values together if they're too far apart(more than 2PI) once they've been
## ordered correctly	
static func adjust_end_theta(start_radian: float, end_radian: float, clockwise: bool) -> float:
	#Do nothing if they're close
	if (Utils.check_angle_matches(start_radian, end_radian)):
		return start_radian
		
	if (clockwise):
		while (start_radian > end_radian):
			end_radian += TAU

	if !clockwise:
		while (start_radian < end_radian):
			end_radian -= TAU

	if absf(end_radian - start_radian) > TAU:
		end_radian = fmod(end_radian - start_radian, TAU) + start_radian

	return end_radian
