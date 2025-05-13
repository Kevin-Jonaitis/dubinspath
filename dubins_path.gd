extends Resource

## We store points for drawing, but we use formulas to determine the position along the curve
## Because of this, arcs will have many points, while the straight line segments will only have 2(start and end)
class_name DubinsPath

var name: String
var length: float = 0
var segments: Array[Segment]
## Points to draw the path. Note that they are evenly spaced on
## arcs, but there are only 2 points for straight lines. So this should be used
## in drawing functions only, not for progress capture. To get progress, use
## get_position_at_offset

# Define a small epsilon value for tolerance
# Vector2.angle() uses (I believe) floats, while atan2() uses doubles percison
# to account for this, don't be very percise when checking if a length is more than 0
# because inconsistencies have been introduced by the different precisions

# This works great with a value of 20, if we were to use that for simply collision boxes
# and snapping points
static var bake_interval: float = 0.5

const EPSILON: float = 1e-4
var calcualtedPoints: bool = false
# use get_points()

var _points: Array[Vector2] = []
# Dumb way to figure out which segment a point is a part of. 
# We don't know because points sometimes overlap in segments and we filter them out in the
# final points array, and there are a bunch
# of edge cases that can determine which segment a point is a part of which 
# frankly I'm too lazy to figure out
var segment_index_for_point: Array[int] = []

# Direction the track is HEADED. start_theta should point INTO the track, end_theta should point OUT of the track
var start_theta: float
var end_theta: float

func _init(name_: String, _segments: Array[Segment], start_theta_: float, end_theta_: float) -> void:
	self.name = name_
	self.bake_interval = bake_interval
	self.segments = filter_segments(_segments)
	for segment: Segment in segments:
		length += segment.length
	self.start_theta = start_theta_
	self.end_theta = end_theta_
	calculate_points()
	
func get_points() -> Array[Vector2]:
	return _points

func get_endpoints_and_directions() -> Array[Array]:
	return [[_points[0], start_theta], [_points[-1], end_theta]]

func calculate_points() -> void:
	for segment_index: int in range(segments.size()):
		var segment: Segment = segments[segment_index]
		if segment is Line:
			for point: Vector2 in segment.points:
				add_point_if_unique(point, segment_index)
		elif segment is Arc:
			for point: Vector2 in segment.points:
				add_point_if_unique(point, segment_index)

## Prevents two of the same point from being added to the 
## points array. This can happen on the boundary of two segments
func add_point_if_unique(point: Vector2, segment_index: int) -> void:
	if _points.is_empty() or not _points[-1].is_equal_approx(point):
		_points.append(point)
		segment_index_for_point.append(segment_index)
	else:
		pass # For breakpointing

# Get the angle(in radians) at a given offset(in pixels) from the start of the path
func get_angle_at_offset(offset: float) -> float:
	var current_length: float = 0
	for segment: Segment in segments:
		if current_length + segment.length >= offset:
			var segment_offset: float = offset - current_length
			if segment is Line:
				var line_seg: Line = segment
				return (line_seg.end - line_seg.start).angle()
			elif segment is Arc:
				var arc_seg: Arc = segment
				var arc_point: Vector2 = arc_seg.get_position_at_offset(segment_offset)
				var vec_from_center: Vector2 = arc_point - arc_seg.center
				var angle_to_center: float = vec_from_center.angle()
				var direction_sign: float = 1.0
				if arc_seg.end_theta < arc_seg.start_theta:
					direction_sign = -1.0
				return angle_to_center + direction_sign * PI / 2.0
		current_length += segment.length
	assert(false, "This should never happen.")
	return 0.0

# Given an offset(in pixels) from the start of the path, return the coordinates on the path at that offset
func get_position_at_offset(offset: float) -> Vector2:
	if offset <= 0:
		return _points[0]
	if offset >= length:
		return _points[-1]
		
	var current_length: float = 0
	for segment: Segment in segments:
		if current_length + segment.length >= offset:
			var segment_offset: float = offset - current_length
			if segment is Line:
				return segment.get_position_at_offset(segment_offset)
			elif segment is Arc:
				return segment.get_position_at_offset(segment_offset)
		current_length += segment.length
	
	return _points[-1]


## Filter out segments that don't have any length; this pretty much only
## happens when it's a straight line
# Filter out segments that are of 0 length, or if after filtering there are no
# valid segments left, return null
func filter_segments(_segments : Array[Segment]) -> Array[Segment]:

	var filtered_segments: Array[Segment] = []
	for segment: Segment in _segments:
		if segment.length > EPSILON:
			filtered_segments.append(segment)
	return filtered_segments


class Line extends Segment:
	var start: Vector2
	var end: Vector2

	func _init(_start: Vector2, _end: Vector2) -> void:
		self.start = _start
		self.end = _end
		self.length = (_end - _start).length()
		calculate_points()

	func calculate_points() -> void:
		var direction: Vector2 = (end - start).normalized()
		var total_points: int = max(2, ceil(length / DubinsPath.bake_interval))
		for i: int in range(total_points):
			var point: Vector2 = start + direction * (i * DubinsPath.bake_interval)
			points.append(point)
		points.append(end) # make sure we always have the end point
		pass


	func get_position_at_offset(offset: float) -> Vector2:
		var t: float = offset / length
		return start.lerp(end, t)

# All the data needed to construct an arc
## We should draw the arc from start_angle towards the value of end_angle in a 
## clockwise direction if start_angle < end_angle and counter-clockwise otherwise.
class Arc extends Segment:
	var center: Vector2
	var start_theta: float
	var end_theta: float
	var radius: float

	func _init(_center: Vector2, _start_theta: float, _end_theta: float, _radius: float) -> void:
		self.center = _center
		self.start_theta = _start_theta
		self.end_theta = _end_theta
		self.radius = _radius
		var thetaDifference: float = _end_theta - _start_theta
		self.length = abs(_radius * thetaDifference)
		self.points = calculate_points_on_arc()
		pass
			
	func calculate_points_on_arc() -> PackedVector2Array:
		var temp_points: PackedVector2Array
		var num_of_points: int = max(2, ceil(length / DubinsPath.bake_interval)) #always have at least 2 points on the arc
		var total_theta: float = end_theta - start_theta
		var theta_slice: float = total_theta / (num_of_points - 1) # Adjust to ensure the last point is included
		for i: int in range(num_of_points):
			var point_theta: float = start_theta + theta_slice * i
			var arc_point: Vector2 = center + Vector2(radius * cos(point_theta), radius * sin(point_theta))
			temp_points.append(arc_point)
		return temp_points

	# Given an offset(in pixels), return the point on the arc
	func get_position_at_offset(offset: float) -> Vector2:
		var t: float = offset / length
		var theta: float
		if start_theta < end_theta:
			# Clockwise traversal
			theta = start_theta + (end_theta - start_theta) * t
		else:
			# Counterclockwise traversal
			theta = start_theta - (start_theta - end_theta) * t
		return center + Vector2(radius * cos(theta), radius * sin(theta))