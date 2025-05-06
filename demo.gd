extends Node2D

var dubins_path: DubinPath2D

func _ready() -> void:
	dubins_path = DubinPath2D.new()
	var start_pos: Vector2 = Vector2(0, 0)
	var start_angle: float = 0.0
	var end_pos: Vector2 = Vector2(100, -100)
	var end_angle: float = PI
	var min_turn_radius: float = 1.0
	dubins_path.calculate_and_draw_paths(start_pos, start_angle, end_pos, end_angle, min_turn_radius, true)
