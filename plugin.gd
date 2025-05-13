@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("DubinsPath2D", "Node2D", preload("res://dubins_path_2d.gd"), preload("res://truck.png"))
	pass


func _exit_tree() -> void:
	pass
