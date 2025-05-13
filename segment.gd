extends RefCounted

class_name Segment

var length: float
var points: PackedVector2Array = []

func get_position_at_offset(_offset: float) -> Vector2:
	assert(false, "This is an abstract class, this should be defined on thes subclass")
	return Vector2.ZERO
