extends Node

class_name Utils

# Error difference we use. Angle calculation errors are pretty abismal in Godot
const EPSILON: float = 1e-4

const GROUND_PLANE: Plane = Plane(Vector3.UP, 0)

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var uuid_counter: int = 0


# Utility script for generating 
func generate_unique_id() -> String:
	uuid_counter += 1
	return str(uuid_counter)
	# rng.randomize()
	# var bytes: Array[int] = []
	# for i: int in range(16):
	# 	bytes.append(rng.randi_range(0, 255))

	# # Set the version to 4 (0100)
	# bytes[6] = (bytes[6] & 0x0F) | 0x40
	# # Set the variant to RFC 4122 (10xx)
	# bytes[8] = (bytes[8] & 0x3F) | 0x80

	# var hex_str: String = ""
	# for b: int in bytes:
	# 	hex_str += String("%02x" % [b])

	# return hex_str.substr(0, 8) + "-" + hex_str.substr(8, 4) + "-" + hex_str.substr(12, 4) + "-" + hex_str.substr(16, 4) + "-" + hex_str.substr(20, 12)


func normalize_angle_0_to_2_pi(angle: float) -> float:
	var normalized: float = fmod(angle, 2 * PI)
	if normalized < 0:
		normalized += 2 * PI
	return normalized

# Used to place this angle between other angles. Normalizing allows us to compare between angles
static func normalize_between_angles(start: float, end: float, angle: float) -> float:
	var normalized: float = angle
	if (start < end):
		while(normalized < start && !check_angle_matches(normalized, start)):
			normalized += TAU
		while(normalized > end && !check_angle_matches(normalized, end)):
			normalized -= TAU
	elif(start > end): # start : 5 end : 0
		while(normalized < end && !check_angle_matches(normalized, end)):
			normalized += TAU
		while(normalized > start && !check_angle_matches(normalized, start)):
			normalized -= TAU	
	else:
		assert(false, "This is weird, we should not be normalizing an angle between two values that are the same")
		return angle
	
	var test_angles_almost_match : bool = check_angle_matches(normalized, start) || check_angle_matches(normalized, end)
	assert(test_angles_almost_match ||  (start < normalized && normalized < end) || (end < normalized && normalized < start), \
	"The angle should be between start and end, getting to this state means there was a bug somewhere")
	
	return normalized

	

# Check if angle matches a within EPSILON.
static func check_angle_matches(angle_a: float, angle_b: float) -> bool:
	if abs(angle_difference(angle_a, angle_b)) <= EPSILON:
		return true
	return false

func measure(func_to_measure: Callable, name_: String) -> Variant:
	
	var start_time: float = Time.get_ticks_usec()
	var result: Variant = func_to_measure.call()
	var end_time: float = Time.get_ticks_usec()
	print(name_ + ": " + str((end_time - start_time) / 1000) + " milliseconds")
	return result


func is_equal_approx(a: float, b: float, tolerance: float = EPSILON) -> bool:
	return abs(a - b) < tolerance

func check_value_epsilon(value: float) -> bool:
	if abs(value) <= EPSILON:
		return true
	elif abs(value - PI) <= EPSILON:
		return false
	assert(false, "Value %f is neither close to 0 nor PI" % value)
	return false

func get_node_by_ground_name(name: String) -> Variant:
	return get_tree().get_first_node_in_group(name)

func draw_3d_line(mesh: ImmediateMesh, points: Array[Vector2], color: Color = Color(1, 0, 0, 1), width: float = 1.0) -> ImmediateMesh:
	mesh.clear_surfaces()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	mesh.surface_set_color(color)
	#mesh.surface_add_vertex(Vector3(0, 10, 0))
	#mesh.surface_set_color(color)
	#mesh.surface_add_vertex(Vector3(10, 10, 10))
	for point: Vector2 in points:
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(point.x, 1, point.y))
	mesh.surface_end()
	return mesh
func draw_thick_polyline(
	mesh: ImmediateMesh,
	points: Array[Vector2],
	color: Color,
	width: float
) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i: int in range(points.size() - 1):
		var start_2d: Vector2 = points[i]
		var end_2d: Vector2 = points[i + 1]
		
		# Convert 2D points to 3D, elevating the y-coordinate by 1 unit.
		var start: Vector3 = Vector3(start_2d.x, 1.0, start_2d.y)
		var end: Vector3 = Vector3(end_2d.x, 1.0, end_2d.y)
		
		# Calculate the direction and a perpendicular vector.
		var direction: Vector3 = (end - start).normalized()
		var perpendicular: Vector3 = Vector3.UP.cross(direction).normalized() * (width / 2.0)
		
		# Define the four vertices of the quad for this segment.
		var v1: Vector3 = start + perpendicular
		var v2: Vector3 = start - perpendicular
		var v3: Vector3 = end + perpendicular
		var v4: Vector3 = end - perpendicular
		
		# Set the color for the vertices.
		mesh.surface_set_color(color)
		
		# Create two triangles (quad) for this segment.
		# First triangle: v1, v2, v3.
		mesh.surface_add_vertex(v1)
		mesh.surface_add_vertex(v2)
		mesh.surface_add_vertex(v3)
		
		# Second triangle: v2, v4, v3.
		mesh.surface_add_vertex(v2)
		mesh.surface_add_vertex(v4)
		mesh.surface_add_vertex(v3)

	mesh.surface_end()


func draw_line_mesh(mesh: ImmediateMesh) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# mesh.surface_set_color(Color(1, 0, 0, 1))
	mesh.surface_add_vertex(Vector3(0, 10, 0))
	# mesh.surface_set_color(Color(1, 0, 0, 1))
	mesh.surface_add_vertex(Vector3(10, 10, 10))
	mesh.surface_add_vertex(Vector3(5, 10, 20))
	mesh.surface_end()

func draw_thick_polyline_strip(
	mesh: ImmediateMesh,
	points: Array[Vector2],
	color: Color,
	width: float
) -> void:
	if points.size() < 2:
		return

	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var half_width: float = width / 2.0
	var offset_points: Array[Vector2] = []

	# Compute a 2D offset for each point:
	for i:int  in range(points.size()):
		var p: Vector2 = points[i]
		var dir: Vector2
		if i == 0:
			# For first point, use direction to next point.
			dir = (points[i + 1] - p).normalized()
		elif i == points.size() - 1:
			# For last point, use direction from previous point.
			dir = (p - points[i - 1]).normalized()
		else:
			# Average the directions from previous and to next.
			var d1: Vector2 = (p - points[i - 1]).normalized()
			var d2: Vector2 = (points[i + 1] - p).normalized()
			dir = (d1 + d2).normalized()
		# Perpendicular in 2D: rotate the direction by 90 degrees.
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		offset_points.append(perp * half_width)

	# Build the triangle strip by adding left and right offset vertices for each point.
	for i: int in range(points.size()):
		var p: Vector2 = points[i]
		var offset: Vector2 = offset_points[i]
		# Convert 2D to 3D (elevate y to 1.0)
		var left: Vector3 = Vector3(p.x + offset.x, 1.0, p.y + offset.y)
		var right: Vector3 = Vector3(p.x - offset.x, 1.0, p.y - offset.y)
		
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(left)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(right)

	mesh.surface_end()

# A cheap way of z stacking. 
func get_y_layer(y_layer_index: int) -> float:
	return y_layer_index * 0.01
	
func convert_to_3d_y_layer(vec_2d: Vector2, y_index: int) -> Vector3:
	return Vector3(vec_2d.x, get_y_layer(y_index), vec_2d.y)

func convert_to_3d_flat(vec_2d: Vector2) -> Vector3:
	return Vector3(vec_2d.x, 0, vec_2d.y)

func convert_to_2d(vec_3d: Vector3) -> Vector2:
	return Vector2(vec_3d.x, vec_3d.z)
