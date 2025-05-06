extends Resource

#TODO: Optimze so that we don't create points for dubin paths that arn't actually used.

#TODO: Allow multiple dubin paths that are E2E to be combined by adding their segments to the segments array	
# find the smallest viable path type
# size it up until it gets to the next path type, or until it's 4x the distance between the points, whatever comes first?

## We store points for drawing, but we use formulas to determine the position along the curve
## Because of this, arcs will have many points, while the straight line segments will only have 2(start and end)
class_name DubinPath

var name: String
var length: float = 0
var segments: Array[Segment]
## Points to draw the path. Note that they are evenly spaced on
## arcs, but there are only 2 points for straight lines. So this should be used
## in drawing functions only, not for progress capture. To get progress, use
## get_point_at_offset

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
# We don't know because points sometimes overlap in segments ad we filter them out in the
# final points array, and there are a bunch
# of edge cases that can determine which segment a point is a part of which 
# frankly I'm too lazy to figure out
#TODO: I should figure this out. Really I should only have 1 overlapping point at the cross point
# for each segment, right?
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

# TODO: Replace this and TrackPointIndex to use track_pos instead of point_index
# Written by Chat-GPT, tested by yours truly
func get_angle_at_point_index(index: int) -> float:
	var result: Array = find_segment_with_point(index)
	var seg_idx: int = result[0]
	var local_idx: int = result[1]
	var seg: Segment = segments[seg_idx]  # Could be either Line or Arc

	if seg is Line:
		# For a straight line, the tangent angle is constant
		var line_seg : Line = seg
		return (line_seg.end - line_seg.start).angle()

	elif seg is Arc:
		# For an arc, get the actual point, then compute tangent from the center
		var arc_seg : Arc = seg
		var arc_point: Vector2 = arc_seg.points[local_idx]
		var vec_from_center: Vector2 = arc_point - arc_seg.center
		var angle_to_center: float = vec_from_center.angle()

		# Determine direction of travel (sign) based on start/end theta
		var direction_sign: float = 1.0
		if arc_seg.end_theta < arc_seg.start_theta:
			direction_sign = -1.0

		# Tangent = radial direction ± 90°, depending on arc direction
		return angle_to_center + direction_sign * PI / 2.0

	# Fallback (should never happen if segments are only Line or Arc)
	assert(false, "This should never happen.")
	return 0.0


# Written by chat gpt verified by yours turly
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
				var arc_point: Vector2 = arc_seg.get_point_at_offset(segment_offset)
				var vec_from_center: Vector2 = arc_point - arc_seg.center
				var angle_to_center: float = vec_from_center.angle()
				var direction_sign: float = 1.0
				if arc_seg.end_theta < arc_seg.start_theta:
					direction_sign = -1.0
				return angle_to_center + direction_sign * PI / 2.0
		current_length += segment.length
	assert(false, "This should never happen.")
	return 0.0

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


# Given an offset(in pixels), return the coordinates on the path at that offset
func get_point_at_offset(offset: float) -> Vector2:
	if offset <= 0:
		return _points[0]
	if offset >= length:
		return _points[-1]
		
	var current_length: float = 0
	for segment: Segment in segments:
		if current_length + segment.length >= offset:
			var segment_offset: float = offset - current_length
			if segment is Line:
				return segment.get_point_at_offset(segment_offset)
			elif segment is Arc:
				return segment.get_point_at_offset(segment_offset)
		current_length += segment.length
	
	return _points[-1]

func get_approx_point_index_at_offset(offset: float) -> int:
	if offset <= 0:
		return 0
	if offset >= length:
		return _points.size() - 1
		
	var current_length: float = 0
	for segment: Segment in segments:
		if current_length + segment.length >= offset:
			var segment_offset: float = offset - current_length
			if segment is Line:
				return segment.get_approx_point_index_at_offset(segment_offset)
			elif segment is Arc:
				return segment.get_approx_point_index_at_offset(segment_offset)
		current_length += segment.length
	
	return _points.size() - 1

func get_offset_to_point(point_index: int) -> float:
	var running_distance: float = 0
	var segment_index: int = segment_index_for_point[point_index]
	for segment: int in range(segment_index):
		running_distance += segments[segment].length
	var point: Vector2 = _points[point_index]
	var segment_distance: float = segments[segment_index].get_distance_from_start_to_point(point)
	return segment_distance + running_distance

# Split this path at the given point index into 2 dubin paths
func split_at_point_index(point_index: int) -> Array[DubinPath]:
	if point_index < 0 or point_index >= _points.size():
		return []  # Return an empty array if the index is out of bounds

	var first_segments: Array[Segment] = []
	var second_segments: Array[Segment] = []
	# var accumulated_indexes = 0
	# # var split_segment_index = 0

	var results: Array = find_segment_with_point(point_index)
	var split_segment_index: int = results[0]
	var segment_point_index: int = results[1]

	var split_segment: Segment = segments[split_segment_index]
	# var point_at_index = split_segment.points[split_segment_index]

	# Add the segments up to the split segment
	first_segments += segments.slice(0, split_segment_index)

	# Split the segment at the point index
	if split_segment is Line:
		var line : Line = split_segment
		var split_point: Vector2 = line.points[segment_point_index]
		first_segments.append(Line.new(line.start, split_point))
		second_segments.append(Line.new(split_point, line.end))
	elif split_segment is Arc:
		var arc : Arc = split_segment
		#split_segment = split_segment as Arc
		# start angle + the total angle * the propotion of the arch we've traversed
		var split_angle: float = arc.start_theta + (arc.end_theta - arc.start_theta) * (segment_point_index / float(arc.points.size() - 1))
		first_segments.append(Arc.new(arc.center, arc.start_theta, split_angle, arc.radius))
		second_segments.append(Arc.new(arc.center, split_angle, arc.end_theta, arc.radius))

	second_segments += segments.slice(split_segment_index + 1, segments.size())


	# Create new DubinPath instances
	var first_path: DubinPath = DubinPath.new(name + "_first_half_splt", first_segments, start_theta, get_angle_at_point_index(point_index))
	var second_path: DubinPath = DubinPath.new(name + "_second_half_splt", second_segments, get_angle_at_point_index(point_index), end_theta)

	return [first_path, second_path]


func find_segment_with_point(point_index: int) -> Array:

	var segment_index: int = segment_index_for_point[point_index]
	var point: Vector2 = _points[point_index]
	var segment: Segment = segments[segment_index]

	# var segment_index: int = 0
	var local_segment_index: int = 0
	for seg_point: Vector2 in segment.points:
		if seg_point == point: # We can compare Vector2 floats here because the points(should) be taken from the same data structure
			return [segment_index, local_segment_index]
		local_segment_index += 1

	assert(false, "Could not find matching point, something's wrong with how we're cosntructing the points for the dubin path from the poitns from the arc/line :(")
	return []

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
		var total_points: int = max(2, ceil(length / DubinPath.bake_interval))
		for i: int in range(total_points):
			var point: Vector2 = start + direction * (i * DubinPath.bake_interval)
			points.append(point)
		points.append(end) # make sure we always have the end point
		pass


	func get_point_at_offset(offset: float) -> Vector2:
		var t: float = offset / length
		return start.lerp(end, t)

	func get_approx_point_index_at_offset(offset: float) -> int:
		var t: float = offset / length
		var test_result: float = t * points.size()
		var result: int = int(floori(t * points.size()))
		return result
	
	func get_distance_from_start_to_point(point: Vector2) -> float:
		return (point - start).length()

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
		var num_of_points: int = max(2, ceil(length / DubinPath.bake_interval)) #always have at least 2 points on the arc
		var total_theta: float = end_theta - start_theta
		var theta_slice: float = total_theta / (num_of_points - 1) # Adjust to ensure the last point is included
		for i: int in range(num_of_points):
			var point_theta: float = start_theta + theta_slice * i
			var arc_point: Vector2 = center + Vector2(radius * cos(point_theta), radius * sin(point_theta))
			temp_points.append(arc_point)
		return temp_points

	# Given an offset(in pixels), return the point on the arc
	func get_point_at_offset(offset: float) -> Vector2:
		var t: float = offset / length
		var theta: float
		if start_theta < end_theta:
			# Clockwise traversal
			theta = start_theta + (end_theta - start_theta) * t
		else:
			# Counterclockwise traversal
			theta = start_theta - (start_theta - end_theta) * t
		return center + Vector2(radius * cos(theta), radius * sin(theta))

	func get_approx_point_index_at_offset(offset: float) -> int:
		var t: float = offset / length
		return int(floori(t * points.size()))

	#TODO: Clean this up somehow, it's much too complicated
	func get_distance_from_start_to_point(point: Vector2) -> float:
		var angle: float = (point - center).angle()
		var normalized_angle: float = Utils.normalize_between_angles(start_theta, end_theta, angle)
		var angle_diff: float = normalized_angle - start_theta
		return abs(radius * angle_diff)

func get_point_at_index(index: int) -> Vector2:
	return _points[index]
