extends RefCounted

class_name Segment

var length: float
var points: PackedVector2Array = []


func get_distance_from_start_to_point(_point: Vector2) -> float:
	assert(false, "This is an abstract class, this should be defined on thes subclass")
	return 0


func get_point_at_offset(_offset: float) -> Vector2:
	assert(false, "This is an abstract class, this should be defined on thes subclass")
	return Vector2.ZERO

func get_approx_point_index_at_offset(_offset: float) -> int:
	assert(false, "This is an abstract class, this should be defined on thes subclass")
	return -1
