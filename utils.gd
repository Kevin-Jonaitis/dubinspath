extends Node

class_name Utils

# Error difference we use. Angle calculation errors are pretty abismal in Godot
const EPSILON: float = 1e-4

# Check if angle matches a within EPSILON.
static func check_angle_matches(angle_a: float, angle_b: float) -> bool:
	if abs(angle_difference(angle_a, angle_b)) <= EPSILON:
		return true
	return false

func is_equal_approx(a: float, b: float, tolerance: float = EPSILON) -> bool:
	return abs(a - b) < tolerance
